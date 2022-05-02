package browse

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
)

type Writer struct {
	ctx          context.Context
	client       *pubsub.Client
	topic        *pubsub.Topic
	subscription *pubsub.Subscription
}

func NewWriter(ctx context.Context) *Writer {
	client, _ := pubsub.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))
	topic, _ := client.CreateTopic(ctx, tryGetenv("TOPIC_ACTION_BROWSE"))
	subscription, _ := client.CreateSubscription(ctx, tryGetenv("SUBSCRIPTION_ACTION_BROWSE"), topic, 0, nil)

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
			log.Fatal("could not pull from writer channel")
		}
		var a store.Action
		if err := json.Unmarshal(msg.Data, &a); err != nil {
			log.Printf("could not decode: %v", err)
			msg.Done(true)
			continue
		}

		a.Uid = msg.Attributes["Uid"]
		go w.Put(&a)
	}
}

func (w *Writer) Put(a *store.Action) {
	e := store.NewEntry(a)

	id := sha1.Sum([]byte(a.Browse.Url))
	e.Story.Id = hex.EncodeToString(id[:])

	cfg := feedly.Config{UrlString: feedly.CloudUrl}
	search := feedly.NewSearch(cfg)
	err := search.Do(w.ctx, a.Browse.Url)
	if err == nil && len(search.Results) > 0 {
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

			if err := e.Store(w.ctx); err != nil {
				log.Printf("could not put page: %v", err)
			}
		}
	} else {
		log.Printf("could not search any feed: %v", err)
	}
}

func tryGetenv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("%s environment variable not set", k)
	}
	return v
}
