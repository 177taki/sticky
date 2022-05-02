package facebook

import (
	"../store"
	"golang.org/x/net/context"
	"testing"
)

var addr = store.Address{
	City:      "Los Altos",
	Country:   "United States",
	Latitude:  37.360557513346,
	Longitude: -122.12372876,
	State:     "CA",
	Street:    "12345 El Monte Rd",
	Zip:       "94022",
}

func TestDump(t *testing.T) {
	ctx := context.Background()
	ets, _ := store.GetAll(ctx)
	for i, e := range *ets {
		t.Logf("%d: Story: %+v", i, e.Story)
		t.Logf("%d: Act: %+v", i, e.Act)
	}
	t.Logf("the num of entries = %d", len(*ets))
}

/*
func TestConvertPutWithoutWebsite(t *testing.T) {
	ctx := context.Background()

	page := make([]Page, 1)
	page[0] = Page{
		Id:          "189319601092676",
		Name:        "Foothill Football Stadium",
		Category:    "Local Business",
		Link:        "https://www.facebook.com/pages/Foothill-Football-Stadium/189319601092676",
		Location:    addr,
		Description: "hogehoge",
	}
	page[0].Picture.Data.Url = "https://scontent.xx.fbcdn.net/v/t1.0-1/c15.0.50.50/p50x50/417197_10149999285992991_711134825_n.png?oh=030a5aa85b268b934e627332f7f3f1e6&oe=590B26D1"

	a := store.Action{
		Uid: "1",
	}
	r := &Result{
		Data: page,
		Act:  a,
	}
	_ = Put(ctx, r)

	ets, _ := store.GetAll(ctx)
	for i, e := range *ets {
		t.Logf("%d: Story: %+v", i, e.Story)
		t.Logf("%d: Act: %+v", i, e.Act)
	}
	t.Logf("the num of entries = %d", len(*ets))
}

func TestConvertPutWithWebsite(t *testing.T) {
	ctx := context.Background()

	page := make([]Page, 1)
	page[0] = Page{
		Id:          "189319601092676",
		Name:        "Foothill Football Stadium",
		Category:    "Local Business",
		Link:        "https://www.facebook.com/pages/Foothill-Football-Stadium/189319601092676",
		Location:    addr,
		Description: "hogehoge",
	}
	page[0].Website = "https://techcrunch.com/"
	page[0].Picture.Data.Url = "https://scontent.xx.fbcdn.net/v/t1.0-1/c15.0.50.50/p50x50/417197_10149999285992991_711134825_n.png?oh=030a5aa85b268b934e627332f7f3f1e6&oe=590B26D1"

	a := store.Action{
		Uid: "1",
	}
	r := &Result{
		Data: page,
		Act:  a,
	}
	_ = Put(ctx, r)

	ets, _ := store.GetAll(ctx)
	for _, e := range *ets {
		t.Logf("%+v", e.Story.Id)
	}
	t.Logf("the num of entries = %d", len(*ets))
}
*/
