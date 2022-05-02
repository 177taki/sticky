package browse

import (
	"../store"
	"golang.org/x/net/context"
	"testing"
)

func TestPut(t *testing.T) {
	ctx := context.Background()

	w := store.Website{
		Url: "http://www.itmedia.co.jp",
	}
	a := store.Action{
		Uid:    "2",
		Browse: w,
	}
	Put(ctx, &a)

	r, _ := store.GetAll(ctx)
	for _, e := range *r {
		t.Logf("%+v", e.Story)
	}
}
