package feedly

import (
	"golang.org/x/net/context"
	"testing"
)

func TestDo(t *testing.T) {
	cfg := Config{
		UrlString: CloudUrl,
	}

	search := NewSearch(cfg)
	ctx := context.Background()

	err := search.Do(ctx, "https://techcrunch.com/")
	t.Logf("error message: %+v", err)
	t.Logf("response data: %+v", search.Results)
}

func TestNewClient(t *testing.T) {
	cfg := Config{
		UrlString: CloudUrl,
	}
	t.Logf("url: %s", cfg.UrlString)
	if cfg.AuthToken == "" {
		t.Logf("token is blank")
	}
	client := NewClient(cfg)

	t.Logf("%s", client.URL.String())
}
