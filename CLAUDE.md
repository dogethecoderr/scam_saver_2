# ScamSaver — Flutter App

## Goal
Initialize a Flutter mobile app that mirrors the existing ScamSaver web app (https://scam-saver.vercel.app). Same five features, same feel — just native mobile.

## Stack
- Flutter 3.x / Dart
- Riverpod 2 for state
- go_router for navigation
- Dio for HTTP
- Google ML Kit for on-device OCR
- flutter_sound for audio recording
- OpenAI Whisper API for speech-to-text

## Screens (match the website exactly)
1. **Home** — tagline, logo, cards linking to each feature
2. **Analyze** (`/analyze`) — text input + submit, show risk result
3. **Screenshot** (`/screenshot`) — image picker → OCR → risk result
4. **Audio** (`/audio`) — file picker or record → transcribe → risk result
5. **Live** (`/live`) — single button, real-time mic stream, live risk updates
6. **Learn** (`/learn`) — scam flashcards / tips

## Project Structure
```
lib/
├── main.dart
├── app.dart              # Router + theme
├── features/
│   ├── home/
│   ├── analyze/
│   ├── screenshot/
│   ├── audio/
│   ├── live/
│   └── learn/
└── shared/
    ├── widgets/          # RiskBadge, ScamCard, LoadingOverlay
    └── services/
        └── claude_service.dart  # Single place for all Claude API calls
```

## Speech-to-Text (OpenAI Whisper)
All audio → text goes through `WhisperService` posting to `https://api.openai.com/v1/audio/transcriptions`.
- Record audio with `flutter_sound`, save as `.m4a` or `.wav`
- POST the file to Whisper (`model: whisper-1`), get back a transcript string
- Pass the transcript into `ClaudeService` for risk analysis
- **Live screen caveat**: Whisper is REST-only, not a streaming WebSocket. Chunk mic audio every ~5 seconds, send each chunk to Whisper, and display rolling results. It won't be instant but works fine for call monitoring.

API key via `--dart-define=OPENAI_API_KEY=...`, never hardcoded.

## Claude API
All LLM calls go through `ClaudeService`. Prompt the model to return JSON:
```json
{ "risk_level": "low|medium|high|critical", "explanation": "...", "red_flags": [] }
```
API key via `--dart-define=ANTHROPIC_API_KEY=...`, never hardcoded.

## Design
- Dark background, clean cards — match the website's minimal aesthetic
- Risk levels: green (low), amber (medium), red (high), dark red (critical)
- Privacy note visible on home: "Your messages are never stored or shared."

## Init Steps
1. `flutter create scamsaver`
2. Add dependencies to `pubspec.yaml`
3. Set up go_router with the 6 routes above
4. Build shared `RiskBadge` widget first, used by all feature screens
5. Implement `ClaudeService`, wire Analyze screen end-to-end as the reference
6. Repeat pattern for Screenshot, Audio, Live, Learn