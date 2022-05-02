package facebook

import (
	"cloud.google.com/go/pubsub"
	"encoding/json"
	fb "github.com/huandu/facebook"
	"golang.org/x/net/context"
	"log"
	"os"
	"strconv"
)

type Search struct {
	ctx          context.Context
	client       *pubsub.Client
	topic        *pubsub.Topic
	subscription *pubsub.Subscription
	app          *fb.App
	radius       int
	limit        int
	topicResults *pubsub.Topic
}

func NewSearch(ctx context.Context) *Search {
	radius, _ := strconv.Atoi(tryGetenv("FBSEARCH_RADIUS"))
	limit, _ := strconv.Atoi(tryGetenv("FBSEARCH_LIMIT"))

	global := fb.New(tryGetenv("FB_APPID"), tryGetenv("FB_APPSECRET"))
	global.RedirectUri = tryGetenv("FB_REDIRECTURI")

	client, _ := pubsub.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))
	topic, _ := client.CreateTopic(ctx, tryGetenv("TOPIC_ACTION_VISIT"))
	subscription, _ := client.CreateSubscription(ctx, tryGetenv("SUBSCRIPTION_ACTION_VISIT"), topic, 0, nil)
	topicResults, _ := client.CreateTopic(ctx, tryGetenv("TOPIC_FACEBOOK_RESULTS"))

	search := &Search{
		ctx:          ctx,
		client:       client,
		topic:        topic,
		subscription: subscription,
		radius:       radius,
		limit:        limit,
		app:          global,
		topicResults: topicResults,
	}
	return search
}

func (f *Search) Run() {
	it, err := f.subscription.Pull(f.ctx)
	if err != nil {
		log.Printf("could not subscribe to pull: %v", err)
	}
	defer it.Stop()

	for {
		msg, err := it.Next()
		if err != nil {
			log.Fatalf("could not pull from channel: %v", err)
		}

		var cl interface{}
		if err := json.Unmarshal(msg.Data, &cl); err != nil {
			log.Printf("could not decode %#v", msg)
			msg.Done(true)
			continue
		}
		cl.(map[string]interface{})["Uid"] = msg.Attributes["Uid"]
		go f.graphSearch(&cl)
		msg.Done(true)
	}
}

func tryGetenv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("%s environment variable not set", k)
	}
	return v
}

func (f *Search) graphSearch(params *interface{}) {
	token := extractToken(params)
	lat, lng := extractLatLng(params)

	session := f.app.Session(token)
	res, err := session.Get("/search", fb.Params{
		"type":     "place",
		"center":   lat + "," + lng,
		"distance": f.radius,
		"limit":    f.limit,
		"fields":   "id,name,category,link,location,picture,cover,description,website",
	})
	if err != nil {
		log.Printf("could not get search results: %v", err)
		return
	}
	res["Act"] = (*params).(map[string]interface{})

	b, _ := json.Marshal(res)

	if _, err := f.topicResults.Publish(f.ctx, &pubsub.Message{Data: b}); err != nil {
		log.Printf("graphSearch: could not publish: %v", err)
	}

}

func extractToken(params *interface{}) string {
	token := (*params).(map[string]interface{})["AccessToken"].(map[string]interface{})["Facebook"].(string)
	return token
}
func extractLatLng(params *interface{}) (lat string, lng string) {
	lat = (*params).(map[string]interface{})["Here"].(map[string]interface{})["Latitude"].(string)
	lng = (*params).(map[string]interface{})["Here"].(map[string]interface{})["Longitude"].(string)
	return lat, lng
}
