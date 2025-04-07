package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/firebase/genkit/go/core"
	"github.com/firebase/genkit/go/genkit"
	"github.com/firebase/genkit/go/plugins/server"
)

func main() {
	ctx := context.Background()
	g, err := genkit.Init(ctx)
	if err != nil {
		log.Fatalf("failed to create Genkit: %v", err)
	}

	basic := genkit.DefineFlow(g, "basic", func(ctx context.Context, subject string) (string, error) {
		foo, err := genkit.Run(ctx, "call-llm", func() (string, error) { return "subject: " + subject, nil })
		if err != nil {
			return "", err
		}
		return genkit.Run(ctx, "call-llm", func() (string, error) { return "foo: " + foo, nil })
	})

	genkit.DefineFlow(g, "parent", func(ctx context.Context, _ any) (string, error) {
		return basic.Run(ctx, "foo")
	})

	type complex struct {
		Key   string `json:"key"`
		Value int    `json:"value"`
	}

	genkit.DefineFlow(g, "complex", func(ctx context.Context, c complex) (string, error) {
		foo, err := core.Run(ctx, "call-llm", func() (string, error) { return c.Key + ": " + strconv.Itoa(c.Value), nil })
		if err != nil {
			return "", err
		}
		return foo, nil
	})

	genkit.DefineFlow(g, "throwy", func(ctx context.Context, err string) (string, error) {
		return "", errors.New(err)
	})

	type chunk struct {
		Count int `json:"count"`
	}

	genkit.DefineStreamingFlow(g, "streamy", func(ctx context.Context, count int, cb func(context.Context, chunk) error) (string, error) {
		i := 0
		if cb != nil {
			for ; i < count; i++ {
				if err := cb(ctx, chunk{i}); err != nil {
					return "", err
				}
			}
		}
		return fmt.Sprintf("done: %d, streamed: %d times", count, i), nil
	})

	genkit.DefineStreamingFlow(g, "streamyThrowy", func(ctx context.Context, count int, cb func(context.Context, chunk) error) (string, error) {
		i := 0
		if cb != nil {
			for ; i < count; i++ {
				if i == 3 {
					return "", errors.New("boom!")
				}
				if err := cb(ctx, chunk{i}); err != nil {
					return "", err
				}
			}
		}
		return fmt.Sprintf("done: %d, streamed: %d times", count, i), nil
	})

	mux := http.NewServeMux()
	for _, a := range genkit.ListFlows(g) {
		mux.HandleFunc("POST /"+a.Name(), genkit.Handler(a))
	}
	log.Fatal(server.Start(ctx, "127.0.0.1:8080", mux))
}