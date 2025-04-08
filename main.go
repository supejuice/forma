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
	jokePrompt, perr := genkit.DefinePrompt(g, "joke",
		ai.WithPromptText(jokeTemplate),
		ai.WithModel(m),
		ai.WithConfig(&ai.GenerationCommonConfig{
			Temperature: 1,}),
		ai.WithInputType(jokeInput{}),
		ai.WithOutputType(jokeOutput{}),
	)
	if perr != nil {
	log.Fatalf("failed to define prompt: %v", perr) 
	}
	genkit.DefineFlow(g, "joke", func(ctx context.Context, input jokeInput) (string, error) {
		
		resp, err := jokePrompt.Execute(ctx, ai.WithInput(input))
		if err != nil {
			log.Fatalf("failed to execute prompt: %v", err) 
			return "", err
		}
		log.Printf("Raw output: %v", resp.Text())
		return resp.Text(), nil
	})

	calTrackingPrompt, perr := genkit.DefinePrompt(g, "calTracking",
		ai.WithPromptText(calTrackingTemplate),
		ai.WithModel(m),
		ai.WithConfig(&ai.GenerationCommonConfig{
			Temperature: 0,}),
		ai.WithInputType(calTrackingInput{}),
		ai.WithOutputType(calTrackingOutput{}),
	)
	if perr != nil {
	log.Fatalf("failed to define prompt: %v", perr) 
	}
	genkit.DefineFlow(g, "calTracking", func(ctx context.Context, input calTrackingInput) (string, error) {
		
		resp, err := calTrackingPrompt.Execute(ctx, ai.WithInput(input))
		if err != nil {
			log.Fatalf("failed to execute prompt: %v", err) 
			return "", err
		}
		log.Printf("Raw output: %v", resp.Text())
		return resp.Text(), nil
	})

	companyInfoPrompt, perr := genkit.DefinePrompt(g, "companyInfo",
		ai.WithPromptText(companyInfoTemplate),
		ai.WithModel(m),
		ai.WithConfig(&ai.GenerationCommonConfig{
			Temperature: 0,}),
		ai.WithInputType(companyInfoInput{}),
		ai.WithOutputType(companyInfoOutput{}),
	)
	if perr != nil {
	log.Fatalf("failed to define prompt: %v", perr) 
	}
	genkit.DefineFlow(g, "companyInfo", func(ctx context.Context, input companyInfoInput) (string, error) {
		
		resp, err := companyInfoPrompt.Execute(ctx, ai.WithInput(input))
		if err != nil {
			log.Fatalf("failed to execute prompt: %v", err) 
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
Hi, I am a person {{height}}cm tall and {{weight}}kg heavy for {{age}} of age. Roast me.`

type jokeInput struct {
	Height  string `json:"height"`
	Weight   string `json:"weight"`
	Age string `json:"age"`
}

type jokeOutput struct {
	Joke string `json:"joke"`
}

const calTrackingTemplate = `measure calories and macros (in grams) in {{food}} of quantity {{quantity}} {{unit_of_measurement}}`

type calTrackingInput struct {
	Food string `json:"food"`
	Quantity float32 `json:"quantity"`
	UnitOfMeasurement string `json:"unit_of_measurement"`
}

type calTrackingOutput struct {
	Calories int `json:"calories"`
	Protein_G int `json:"protein_g"`
	Fat_G int `json:"fat_g"`
	Carbs_G int `json:"carbs_g"`
}
const companyInfoTemplate = `
Provide detailed information about the company with ticker symbol {{ticker}}. Include the following:
1. Subsidiaries (listed and unlisted)
2. Related companies
3. Brands`

type companyInfoInput struct {
	Ticker string `json:"ticker"`
}

type companyInfoOutput struct {
	Subsidiaries    []string `json:"subsidiaries"`
	RelatedCompanies []string `json:"related_companies"`
	Brands          []string `json:"brands"`
}