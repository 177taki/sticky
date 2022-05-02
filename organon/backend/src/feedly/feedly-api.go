package feedly

import (
	"encoding/json"
	"golang.org/x/net/context"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"path"
)

const (
	CloudUrl   = "https://cloud.feedly.com"
	SandboxUrl = "https://sandbox.feedly.com"
)

type Config struct {
	UrlString string
	AuthToken string
}

type Client struct {
	URL        *url.URL
	HttpClient *http.Client
	AuthToken  string
}

type Search struct {
	Client  *Client
	Results []struct {
		LastUpdated   int64
		Score         float64
		Description   string
		DeliciousTags []string
		ContentType   string
		Language      string
		CoverUrl      string
		IconUrl       string
		Title         string
		Website       string
		FeedId        string
		VisualUrl     string
		Subscribers   int64
	}
}

func NewSearch(cf Config) *Search {
	return &Search{
		Client: NewClient(cf),
	}
}

func NewClient(cf Config) *Client {
	endpoint, err := url.Parse(cf.UrlString)
	if err != nil {
		log.Fatalf("could not parse url: %v", err)
	}

	return &Client{
		URL:        endpoint,
		HttpClient: http.DefaultClient,
		AuthToken:  cf.AuthToken,
	}
}

func (c *Client) NewRequest(ctx context.Context, method, spath string, query map[string]string, body io.Reader) (*http.Request, error) {
	u := *c.URL
	u.Path = path.Join(c.URL.Path, spath)

	q := u.Query()
	for k, v := range query {
		q.Add(k, v)
	}
	u.RawQuery = q.Encode()

	req, err := http.NewRequest(method, u.String(), body)
	if err != nil {
		log.Printf("could not create new request: %v", err)
		return nil, err
	}

	//req = req.WithContext(ctx)

	if c.AuthToken != "" {
		req.Header.Set("Authorization", c.AuthToken)
	}
	return req, nil
}

func (s *Search) Do(ctx context.Context, target string) error {
	params := map[string]string{
		"query": target,
	}

	req, err := s.Client.NewRequest(ctx, "GET", "/v3/search/feeds", params, nil)
	if err != nil {
		log.Printf("could not create new request for search: %v", err)
		return err
	}

	res, err := s.Client.HttpClient.Do(req)

	if err != nil {
		log.Printf("could not Do search request: %v", err)
		return err
	}
	defer res.Body.Close()
	b, _ := ioutil.ReadAll(res.Body)

	if err := json.Unmarshal(b, s); err != nil {
		log.Printf("could not decode %v", res)
		return err
	}

	return nil
}
