package main

import (
	"browse"
	"cloud.google.com/go/pubsub"
	"encoding/base64"
	"encoding/json"
	"facebook"
	"fmt"
	"github.com/gorilla/mux"
	"golang.org/x/net/context"
	"google.golang.org/appengine"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"store"
)

type UserInfo struct {
	Issuer string
	Id     string
}

type Topic struct {
	visit  *pubsub.Topic
	browse *pubsub.Topic
}

var (
	client *pubsub.Client
	topic  Topic
)

func main() {

	ctx := context.Background()

	client, _ = pubsub.NewClient(ctx, tryGetenv("GCLOUD_PROJECT"))
	topic.visit = client.Topic(tryGetenv("TOPIC_ACTION_VISIT"))
	topic.browse = client.Topic(tryGetenv("TOPIC_ACTION_BROWSE"))

	f := facebook.NewSearch(ctx)
	fw := facebook.NewWriter(ctx)
	bw := browse.NewWriter(ctx)

	go f.Run()
	go fw.Run()
	go bw.Run()

	r := mux.NewRouter()

	r.Path("/action/visit").Methods("POST", "OPTIONS").
		Handler(corsHandler(visitHandler))
	r.Path("/action/browse").Methods("POST").
		HandlerFunc(corsHandler(browseHandler))
	r.Path("/stories").Methods("GET").
		HandlerFunc(corsHandler(storiesHandler))
	r.Path("/stories/{id}/{subscription:(?:subscribe|unsubscribe)}").Methods("POST").
		HandlerFunc(corsHandler(subscribeHandler))

	http.Handle("/", r)
	appengine.Main()
}

// corsHandler wraps a HTTP handler and applies the appropriate responses for Cross-Origin Resource Sharing.
type corsHandler http.HandlerFunc

func (h corsHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	if r.Method == "OPTIONS" {
		w.Header().Set("Access-Control-Allow-Headers", "Authorization")
		return
	}
	h(w, r)
}

func visitHandler(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()

	uinfo := decodeToken(r)
	uid := map[string]string{"Uid": uinfo.Id}

	b, _ := ioutil.ReadAll(r.Body)
	if _, err := topic.visit.Publish(ctx, &pubsub.Message{Data: b, Attributes: uid}); err != nil {
		log.Printf("FRONTEND: could not publish: %v", err)
	}
}

func browseHandler(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()

	uinfo := decodeToken(r)
	uid := map[string]string{"Uid": uinfo.Id}

	b, _ := ioutil.ReadAll(r.Body)
	if _, err := topic.browse.Publish(ctx, &pubsub.Message{Data: b, Attributes: uid}); err != nil {
		log.Printf("FRONTEND: could not publish: %v", err)
	}
}

func storiesHandler(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()

	var subscription = false
	q := r.URL.Query()
	if q.Get("subscription") == "yes" {
		subscription = true
	}

	uinfo := decodeToken(r)
	query := store.NewQuery(ctx, uinfo.Id, subscription, 100)

	entries := query.Pull(ctx)
	if len(*entries) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	b, err := json.Marshal(entries)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s", string(b))
}

func subscribeHandler(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()
	uinfo := decodeToken(r)

	var subscription = true
	vars := mux.Vars(r)
	if vars["subscription"] == "unsubscribe" {
		subscription = false
	}
	if err := store.Subscribe(ctx, uinfo.Id, vars["id"], subscription); err != nil {
		log.Printf("could not update subscription (%s%s) to %v", uinfo.Id, vars["id"], subscription)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func decodeToken(r *http.Request) *UserInfo {
	encodedInfo := r.Header.Get("X-Endpoint-API-UserInfo")
	if encodedInfo == "" {
		return nil
	}

	b, err := base64.StdEncoding.DecodeString(encodedInfo)
	if err != nil {
		//errorf(w, http.StatusInternalServerError, "Could not decode auth info: %v", err)
		return nil
	}
	var uinfo UserInfo
	if err := json.Unmarshal(b, &uinfo); err != nil {
		log.Printf("could not unmarshal: %v", err)
		return nil
	}
	return &uinfo
}

// errorf writes a swagger-compliant error response.
func errorf(w http.ResponseWriter, code int, format string, a ...interface{}) {
	var out struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	}

	out.Code = code
	out.Message = fmt.Sprintf(format, a...)

	b, err := json.Marshal(out)
	if err != nil {
		http.Error(w, `{"code": 500, "message": "Could not format JSON for original message."}`, 500)
		return
	}

	http.Error(w, string(b), code)
}

func tryGetenv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		log.Fatalf("%s environment variable not set", k)
	}
	return v
}
