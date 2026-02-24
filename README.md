# Forma

Forma is an AI-assisted nutrition and calorie tracking project.

The primary product is the Flutter app in `forma_flutter`, focused on fast meal logging and local calorie trend tracking.

## Main App (`forma_flutter`)

Implemented features:

- Mistral API key onboarding (secure local storage)
- Free-text meal input -> Mistral nutrition extraction
- Calories + macros + sodium estimation
- Local persistence with SQLite
- Trend analytics for `7D`, `30D`, `90D`, and custom range
- Daily calorie target management
- Riverpod state management
- Design-system-driven UI with lightweight animations

## Flutter Quick Start

```zsh
cd forma_flutter
flutter pub get
flutter run
```

On first launch, add your Mistral API key in the onboarding screen.

## Flutter Quality Checks

```zsh
cd forma_flutter
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
flutter build apk --debug
```

## Go App (Genkit Server)

The repository also includes a Go + Genkit server in `main.go` with these flows:

- `joke`
- `calTracking`
- `companyInfo`

### Go App Prerequisites

Install Node.js (for Genkit CLI):

```zsh
brew update
brew install node
node -v
npm -v
```

Install JS dependencies at repo root:

```zsh
npm install
```

Install/update Go dependencies:

```zsh
go mod tidy
```

Set Gemini API key (required by `googlegenai` plugin in `main.go`):

```zsh
export GEMINI_API_KEY=<YOUR_KEY>
```

### Run Go App

Run directly:

```zsh
go run main.go
```

Optional Genkit dev mode (if preferred in your local workflow):

```zsh
npx genkit start -- go run main.go
```

The server starts on `127.0.0.1:8080` and flow endpoints follow:

```text
POST http://127.0.0.1:8080/<flowName>
```

Examples:

- `POST /joke`
- `POST /calTracking`
- `POST /companyInfo`

## Repo Layout

- `forma_flutter/` Flutter client app (active product)
- `main.go`, `go.mod` Go/Genkit flows

## Additional Docs

- `forma_flutter/README.md`
- `forma_flutter/docs/YEGOR256_GUIDELINES.md`
- `forma_flutter/ASSETS_ATTRIBUTION.md`

## License

This project is licensed under Apache 2.0. See `LICENSE`.
