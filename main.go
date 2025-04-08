package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"

	"github.com/firebase/genkit/go/ai"
	"github.com/firebase/genkit/go/genkit"
	"github.com/firebase/genkit/go/plugins/googlegenai"
	"github.com/firebase/genkit/go/plugins/server"
)

func main() {
	ctx := context.Background()
	g, err := genkit.Init(ctx,  genkit.WithPlugins(&googlegenai.GoogleAI{}))
	if err != nil {
		log.Fatalf("failed to create Genkit: %v", err)
	}

	genkit.DefineFlow(g, "jokesFlow", func(ctx context.Context, input string) (string, error) {
		m := googlegenai.GoogleAIModel(g, "gemini-2.0-flash")
		if m == nil {
			return "", errors.New("jokesFlow: failed to find model")
		}

		resp, err := genkit.Generate(ctx, g,
			ai.WithModel(m),
			ai.WithConfig(&ai.GenerationCommonConfig{
				Temperature: 0,
				Version:     "gemini-2.0-flash-001",
			}),
			ai.WithPromptText(fmt.Sprintf(`Tell silly short jokes about %s`, input)))
		if err != nil {
			return "", err
		}

		text := resp.Text()
		return text, nil
	})

	mux := http.NewServeMux()
	for _, a := range genkit.ListFlows(g) {
		mux.HandleFunc("POST /"+a.Name(), genkit.Handler(a))
	}
	log.Fatal(server.Start(ctx, "127.0.0.1:8080", mux))
}