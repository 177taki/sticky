package store

import (
	"golang.org/x/net/context"
	"testing"
)

func TestGetAll(t *testing.T) {
	ctx := context.Background()

	r, _ := GetAll(ctx)

	t.Logf("%+v", r)
}

func TestQueryOnCursor(t *testing.T) {
	ctx := context.Background()

	q := NewQuery(ctx, "1", false, 1)

	var r *[]Entry
	r = q.GetRecursive(ctx)
	t.Logf("%+v", (*r)[0].Story.Id)

	r = q.GetRecursive(ctx)
	t.Logf("%+v", (*r)[0].Story.Id)
}

func TestQueryNoCursor(t *testing.T) {
	ctx := context.Background()

	q := NewQuery(ctx, "1", false, 1)

	var r *[]Entry
	r = q.GetRecursive(ctx)
	i1 := (*r)[0].Story.Id

	q.cursor = ""

	r = q.GetRecursive(ctx)
	i2 := (*r)[0].Story.Id

	if i1 != i2 {
		t.Error("1st: %+v, 2nd: %+v", i1, i2)
	}
}
