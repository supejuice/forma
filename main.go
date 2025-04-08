package main

import (
	"context"
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
	m := googlegenai.GoogleAIModel(g, "gemini-2.0-flash")
	jokePrompt, err := genkit.DefinePrompt(g, "joke",
		ai.WithPromptText(jokeTemplate),
		ai.WithModel(m),
		ai.WithConfig(&ai.GenerationCommonConfig{
			Temperature: 1,}),
		ai.WithInputType(jokeInput{}),
		ai.WithOutputType(jokeOutput{}),
	)
	if err != nil {
	log.Fatalf("failed to define prompt: %v", err) 
	}
	genkit.DefineFlow(g, "joke", func(ctx context.Context, input jokeInput) (string, error) {
		
		resp, err := jokePrompt.Execute(ctx, ai.WithInput(input))
		if err != nil {
			log.Fatalf("failed to define prompt: %v", err) 
			return "", err
		}

		log.Printf("Raw output: %v", resp.Text())
		return resp.Text(), nil
	})

	mux := http.NewServeMux()
	for _, a := range genkit.ListFlows(g) {
		mux.HandleFunc("POST /"+a.Name(), genkit.Handler(a))
	}
	log.Fatal(server.Start(ctx, "127.0.0.1:8080", mux))
}

const jokeTemplate = `
Hi, I am a person {{height}}cm tall and {{weight}}kg heavy for {{age}} of age. Roast me
 based on the following info.`

type jokeInput struct {
	Height  string `json:"height"`
	Weight   string `json:"weight"`
	Age string `json:"age"`
}

type jokeOutput struct {
	Joke string `json:"joke"`
	Error string `json:"error"`
}