package store

import (
	"cloud.google.com/go/datastore"
	"encoding/json"
	"golang.org/x/net/context"
	"google.golang.org/api/iterator"
	"log"
	"os"
)

type Address struct {
	BriefAddress string
	Speed        string
	Direction    string
	Zip          string
	Street       string
	City         string
	State        string
	Country      string
	Latitude     json.Number `json:,Number`
	Longitude    json.Number `json:,Number`
}

type Website struct {
	Url   string
	Title string
}

type Image struct {
	Offset_x float64
	Offset_y float64
	Source   string
}

type Token struct {
	Facebook string
	Feedly   string
	Google   string
}

type Action struct {
	Uid           string
	AccessToken   Token
	Situation     string
	Scene         Website
	Browse        Website
	Here          Address
	UnixTimestamp float64
	Locale        string
}

type StoryModel struct {
	Id         string
	Attributes struct {
		Subject     string
		Concern     string
		Author      string
		Title       string
		Description string
		Cover       Image
		Uri         string
		Mainpage    Website
		IconUrl     string
		Location    Address
		LastUpdated int64
	}
}

type Entry struct {
	Story        *StoryModel
	Act          *Action
	Subscription bool
}

type Query struct {
	client       *datastore.Client
	cursor       string
	query        *datastore.Query
	subscription bool
}

func NewEntry(a *Action) *Entry {
	e := &Entry{
		Story: &StoryModel{Id: "x"},
		Act:   a,
	}
	return e
}

func (e *Entry) Store(ctx context.Context) error {
	datastoreClient, err := datastore.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))
	if err != nil {
		log.Printf("could not create datastore client: %v", err)
		return err
	}

	k := datastore.NameKey(tryGetenv("KIND"), e.Act.Uid+e.Story.Id, nil)

	if _, err := datastoreClient.Put(ctx, k, e); err != nil {
		log.Printf("could not put (%s) to datastore: %v", e.Story.Id, err)
		return err
	}
	return nil
}

func GetAll(ctx context.Context) (*[]Entry, error) {
	datastoreClient, _ := datastore.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))

	q := datastore.NewQuery(tryGetenv("KIND")).Limit(100)

	ets := make([]Entry, 0)
	if _, err := datastoreClient.GetAll(ctx, q, &ets); err != nil {
		log.Printf("could not retrive entries: %v", err)
		return nil, err
	}
	return &ets, nil
}

func tryGetenv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("%s environment variable not set", k)
	}
	return v
}

func NewQuery(ctx context.Context, uid string, subscription bool, limit int) *Query {
	c, _ := datastore.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))
	q := datastore.NewQuery(tryGetenv("KIND")).Filter("Act.Uid =", uid).Filter("Subscription =", subscription).Order("-Act.UnixTimestamp").Limit(limit)

	query := &Query{
		client: c,
		query:  q,
	}
	return query
}

func (q *Query) isRecursive(ctx context.Context) bool {
	if c, err := datastore.DecodeCursor(q.cursor); err == nil {
		q.query = q.query.Start(c)
		return true
	}
	return false
}

func (q *Query) Pull(ctx context.Context) *[]Entry {
	var results []Entry
	t := q.client.Run(ctx, q.query)
	for {
		var e Entry
		_, err := t.Next(&e)
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Printf("could not fetch next entry: %v", err)
			break
		}
		results = append(results, e)
	}

	if c, err := t.Cursor(); err == nil {
		q.cursor = c.String()
	}
	return &results
}

func Subscribe(ctx context.Context, uid string, sid string, subscription bool) error {
	c, _ := datastore.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))

	k := datastore.NameKey(tryGetenv("KIND"), uid+sid, nil)
	e := new(Entry)
	if err := c.Get(ctx, k, e); err != nil {
		log.Printf("could not get entry %s %s which should be.", uid, sid)
		return err
	}
	e.Subscription = subscription

	if _, err := c.Put(ctx, k, e); err != nil {
		log.Printf("could not put (%s) to datastore: %v", e.Story.Id, err)
		return err
	}
	return nil
}
