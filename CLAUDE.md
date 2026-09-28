# Expense Tracker (Flutter)

Portfolio project: an offline-first expense tracker.
The developer is a junior who is learning, so explanations matter as much as code.

## Stack
Flutter, Riverpod (Notifier/AsyncNotifier), go_router, Drift, dio

## Architecture
- Feature-based structure: lib/features/<feature>/{data,domain,presentation}
- UI contains no business logic; logic lives in providers and repositories
- Every screen handles loading, error and empty states

## Working rules
- Before making changes, show me a plan and wait for my confirmation
- One task at a time, small changes only
- Do not add new packages without my permission
- Write unit tests for every piece of new logic
- After changes, run `flutter analyze` and `flutter test`
- Explain what you changed and why, in simple terms
- Never commit secrets (API keys, .env files, key.properties)

## Commands
- Run: `flutter run`
- Analyze: `flutter analyze`
- Test: `flutter test`

## Target platforms
Android and iOS only. The linux, macos, windows and web folders are not used in this project.