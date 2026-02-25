# Forma Flutter

Simple nutrition companion app focused on fast meal logging and calorie trends for weight-loss consistency.

## What is implemented

- Mistral API key onboarding screen with secure local storage
- Main meal logging screen:
  - free-text meal input
  - recent input chips for quick re-entry
  - Mistral-powered nutrition extraction (calories + macros + sodium)
  - immediate nutrition breakdown card
- Local persistence with SQLite:
  - meal logs
  - nutrition values
  - daily calorie target
- Trends screen:
  - 7D, 30D, 90D, custom date range
  - animated calorie chart
  - totals, daily average, and over-target day count
- Riverpod state management
- Design system tokens (color, spacing, radius, motion) + reusable UI components
- Basic test coverage for AI parsing and date-range logic

## Architecture

Feature-first, layered structure inspired by Genkit-style flow boundaries:

- `presentation/` UI screens + widgets
- `application/` Riverpod notifiers/providers
- `domain/` immutable entities/value objects
- `infrastructure/` Mistral API client, flow parser, SQLite repository

Mistral logic is isolated behind `NutritionFlow` (`MistralNutritionFlow`) so the model provider can be swapped without changing UI code.

## Setup

1. Ensure Flutter is installed.
2. From `forma_flutter`:

```bash
flutter pub get
flutter run
```

3. On first launch, enter your Mistral API key on the onboarding screen.
4. If you need a key:
   - sign in at `https://console.mistral.ai`
   - open `API Keys`
   - create a new key and copy it once

## Validation commands used

```bash
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
flutter build apk --debug
```

## Notes

- Nutrition data is estimated by the model from free text and should be treated as guidance.
- Logs are saved locally on-device.
- Visual image resources are from free stock sources. See `ASSETS_ATTRIBUTION.md`.
