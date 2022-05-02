package facebook

import (
	"cloud.google.com/go/pubsub"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"feedly"
	"golang.org/x/net/context"
	"log"
	"os"
	"store"
	"sync"
)

type Result struct {
	Data []Page
	Act  store.Action
}

type Page struct {
	Id       string
	Name     string
	Category string
	Link     string
	Location store.Address
	Picture  struct {
		Data struct {
			Url string
		}
	}
	Cover       store.Image
	Description string
	Website     string
}

type Writer struct {
	ctx          context.Context
	client       *pubsub.Client
	topic        *pubsub.Topic
	subscription *pubsub.Subscription
}

func NewWriter(ctx context.Context) *Writer {
	client, _ := pubsub.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))
	topic, _ := client.CreateTopic(ctx, tryGetenv("TOPIC_FACEBOOK_RESULTS"))
	subscription, _ := client.CreateSubscription(ctx, tryGetenv("SUBSCRIPTION_FACEBOOK_RESULTS"), topic, 0, nil)

	writer := &Writer{
		ctx:          ctx,
		client:       client,
		topic:        topic,
		subscription: subscription,
	}

	return writer
}

func (w *Writer) Run() {
	it, err := w.subscription.Pull(w.ctx)
	if err != nil {
		log.Fatal(err)
	}
	defer it.Stop()

	for {
		msg, err := it.Next()
		if err != nil {
			log.Fatalf("could not pull from writer channel")
		}

		var r Result
		if err := json.Unmarshal(msg.Data, &r); err != nil {
			log.Printf("FACEBOOK Write: could not decode: %v", err)
			msg.Done(true)
			continue
		}
		go w.Put(&r)

		msg.Done(true)
	}
}

func tryGetenvv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("%s environment variable not set", k)
	}
	return v
}

func (w *Writer) Put(r *Result) error {

	wg := &sync.WaitGroup{}
	for _, page := range r.Data {
		wg.Add(1)
		go func(p Page) {
			e := store.NewEntry(&(r.Act))
			convert(w.ctx, &p, e)

			if err := e.Store(w.ctx); err != nil {
				log.Printf("could not put page %v: %v", p.Id, err)
			}
			wg.Done()
		}(page)
	}
	wg.Wait()
	return nil
}

func convert(ctx context.Context, page *Page, e *store.Entry) {
	e.Story.Id = page.Id
	e.Story.Attributes.Subject = page.Category
	e.Story.Attributes.Author = ""
	e.Story.Attributes.Title = page.Name
	e.Story.Attributes.Description = page.Description
	e.Story.Attributes.Cover = page.Cover
	e.Story.Attributes.Mainpage.Url = page.Link
	e.Story.Attributes.IconUrl = page.Picture.Data.Url
	e.Story.Attributes.Location = page.Location

	if page.Website != "" {
		cfg := feedly.Config{
			UrlString: feedly.CloudUrl,
		}
		search := feedly.NewSearch(cfg)
		err := search.Do(ctx, page.Website)
		//if err := search.Do(ctx, page.Website); err == nil && len(search.Results) > 0 {
		if err != nil {
			log.Printf("could not search any feed: %v", err)
		} else if len(search.Results) > 0 {
			for _, r := range search.Results {
				b := sha1.Sum([]byte(r.FeedId))
				e.Story.Id = hex.EncodeToString(b[:])
				e.Story.Attributes.Title = r.Title
				e.Story.Attributes.Description = r.Description
				e.Story.Attributes.Cover = store.Image{Source: r.CoverUrl}
				e.Story.Attributes.Uri = r.FeedId
				e.Story.Attributes.Mainpage.Url = r.Website
				e.Story.Attributes.IconUrl = r.IconUrl
				e.Story.Attributes.LastUpdated = r.LastUpdated
			}
		}
	}
}
