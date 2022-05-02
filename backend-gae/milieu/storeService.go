package milieu

import (
	//"html/template"
	"fmt"
	"time"
	"strconv"
	//"net/url"
	"net/http"
	//"net/http/httputil"
	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
//	"google.golang.org/appengine/blobstore"
//	"google.golang.org/appengine/image"
	"google.golang.org/appengine/log"
	"io/ioutil"
	"encoding/json"
	"github.com/gorilla/mux"
)

type milieu struct {
	Sensor string `json: "sensor"`
	Data []milieuData `json: "data"`
}
type milieuData struct {
	Context context `json: "context"`
	Series series `json: "series"`
	Subscription bool `json: "subscription"`
}
type series struct {
	Id string `json: "id"`
	Attributes attributes `json: "attributes"`
}
type attributes struct {
	Version string `json: "version"`
	Subject string `json: "subject"`
	Predicate string `json: "predicate"`
	Author string `json: "author"`
	Title string `json: "title"`
	Depiction string `json: "depiction"`
	Image string `json: "image"`
	Uri string `json: "uri"`
	Mainpage string `json: mainpage`
	Icon string `json: icon`
	Location coordinates `json: "location"`
}
type context struct {
	Moment string `json: "moment"`
	Address string `json: "address"`
	Location coordinates `json: "location"`
	Look string `json: "look"`
	Website string `json: "website"`
	Situation string `json: "situation"`
	Timestamp int64 `json: "timestamp"`
}
type snapshot struct {
	Url string
}
type coordinates struct {
	Lat string `json: "lat"`
	Lng string `json: "lng"`
}

func init() {
	const seriesPath string = "/v0/api/series"
	const milieuPath string = "/v0/api/milieu"
	const milieuKind string = "milieux"

	r := mux.NewRouter()
	r.HandleFunc("/v0/api/sweep", sweepStale)
	r.HandleFunc(milieuPath, pullMilieu).Methods("GET")
	r.HandleFunc(milieuPath, pushMilieu).Methods("POST")
	r.HandleFunc(seriesPath+"/{id}", subscribe).Methods("POST")
	r.HandleFunc(seriesPath, forceGarbage).Methods("DELETE")
	http.Handle("/v0/api/", r)
}

func sweepStale(w http.ResponseWriter, r * http.Request) {
	c := appengine.NewContext(r)
	var duration int64 = 172800*2
	lastTimestamp := time.Now().Unix()-duration
	log.Debugf(c, "%d", lastTimestamp)
	kinds, err := datastore.Kinds(c)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	for _, kind := range kinds {
		q := datastore.NewQuery(kind).Filter("Context.Timestamp <", lastTimestamp).Filter("Subscription =", false).KeysOnly()
		keys, _ := q.GetAll(c, nil)
		for from := 0; from < len(keys); from += 100 {
			to := from + 100
			if to > len(keys) {
				to = len(keys)
			}
			_keys := keys[from:to]
			err := datastore.DeleteMulti(c, _keys)

			if err != nil {
				log.Errorf(c, err.Error())
				http.Error(w, "Cannot sweep data stale.", http.StatusInternalServerError)
			}

		}

	}
	w.WriteHeader(http.StatusOK)
}

func forceGarbage(w http.ResponseWriter, r *http.Request) {
	sensor := r.FormValue("sensor")
	var days int64 = 172800*2
	now := strconv.FormatInt(time.Now().Unix()-days, 10)
	c := appengine.NewContext(r)
	q := datastore.NewQuery(sensor).Filter("Context.Timestamp <", now).Filter("Subscription =", false).KeysOnly()
	keys, _ := q.GetAll(c, nil)
	if err := datastore.DeleteMulti(c, keys); err != nil {
		log.Errorf(c, err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func subscribe(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	sensor := r.FormValue("sensor")
	c := appengine.NewContext(r)

	//data := milieuData{Subscription: true}
	var data milieuData
	key := datastore.NewKey(c, milieuKind, sensor+"-"+id, 0, nil)
	datastore.Get(c, key, &data)
	data.Subscription = true

	if _, err := datastore.Put(c, key, &data); err != nil {
		log.Errorf(c, err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func pushMilieu(w http.ResponseWriter, r *http.Request) {
	c := appengine.NewContext(r)

	var m milieu
	//err := json.NewDecoder(r.Body).Decode(&m)

	b, err := ioutil.ReadAll(r.Body)
	if err != nil {
		log.Errorf(c, err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	err = json.Unmarshal(b, &m)
	if err != nil {
		log.Errorf(c, err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	log.Debugf(c, "%+v", m)

	//keys := make([]*datastore.Key, len(m.Data))

	var d milieuData
	var key *datastore.Key
//	for index, each := range m.Data {
//		keys[index] = datastore.NewKey(c, m.Sensor, each.Series.Id, 0, nil)
	for _, each := range m.Data {
		key = datastore.NewKey(c, milieuKind, sensor+"-"+each.Series.Id, 0, nil)
		err = datastore.Get(c, key, &d)
		if err == datastore.ErrNoSuchEntity {
			_, err = datastore.Put(c, key, &each)

			if err != nil {
				log.Errorf(c, err.Error())
				http.Error(w, "Cannot store series into Datastore.", http.StatusInternalServerError)
				return
			}
		} else {
			log.Debugf(c, "Key: %s already exists", key.Encode())
		}
	}
	/*
	_, err = datastore.PutMulti(c, keys, m.Data)
	if err != nil {
		log.Errorf(c, err.Error())
		http.Error(w, "Cannot store series into Datastore.", http.StatusInternalServerError)
		return
	}
	*/
}

func pullMilieu(w http.ResponseWriter, r *http.Request) {
	sensor := r.FormValue("sensor")
	subscription := false
	if r.FormValue("subscription") == "true" {
		subscription = true
	}
	c := appengine.NewContext(r)
	q := datastore.NewQuery(milieuKind).Filter("__key__ <", sensor+"-"+'\uFFFD').Filter("__key__ >", sensor+"-").Filter("Subscription =", subscription).Order("-Context.Timestamp").Limit(100)

	var data []milieuData
	if _, err := q.GetAll(c, &data); err != nil {
		log.Errorf(c, err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if len(data) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	bytes, err := json.Marshal(data)
	if err != nil {
		log.Errorf(c, err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s", string(bytes))
}

