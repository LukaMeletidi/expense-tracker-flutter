# Expense Tracker

[![CI](https://github.com/LukaMeletidi/expense-tracker-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/LukaMeletidi/expense-tracker-flutter/actions/workflows/ci.yml)

An offline-first expense tracker for Android and iOS, built with Flutter,
Riverpod and Drift. Every expense is stored on the device, so the app works
without an internet connection.

<p>
  <img src="docs/screenshots/list.png" alt="Expense list" width="250">
  <img src="docs/screenshots/add_form.png" alt="Add expense form" width="250">
  <img src="docs/screenshots/empty_state.png" alt="Empty state" width="250">
</p>

## Features

- Add an expense with a title, amount, category, date and an optional note
- Browse expenses one month at a time, newest day first
- Swipe an expense away to delete it
- Data is saved in a local SQLite database and survives app restarts
- Form validation (required title, amount must be a valid number above 0)
- Every screen handles its loading, error and empty states
- Light and dark themes that follow the phone's setting

## Tech stack

| Package | Used for |
|---|---|
| [Flutter](https://flutter.dev) | UI for Android and iOS from one codebase |
| [Riverpod](https://riverpod.dev) | State management; keeps logic out of widgets and makes it easy to swap dependencies in tests |
| [go_router](https://pub.dev/packages/go_router) | Navigation by path (`/`, `/add`) instead of pushing widgets by hand |
| [Drift](https://drift.simonbinder.eu) | Type-safe SQLite; queries return a `Stream` that emits again whenever the table changes |

## Architecture

The code is organised by feature, and each feature is split into three layers:

```
lib/
├── core/                       shared by the whole app
│   ├── clock/                  clockProvider ("now", replaceable in tests)
│   ├── database/               AppDatabase and its provider
│   ├── formatting/             formatCents / parseCents
│   ├── router/                 go_router setup
│   └── theme/                  light and dark themes
└── features/expenses/
    ├── domain/                 Expense, CalendarMonth, ExpenseRepository
    │                           interface, dateOnly
    │                           (pure Dart: no Flutter, no Drift)
    ├── data/                   Drift table, DriftExpenseRepository
    └── presentation/           screens, providers, form rules
```

How data flows when the list is shown, and after an expense is added:

```mermaid
flowchart LR
    Screen["ExpenseListScreen /<br>AddExpenseScreen"] -->|"watch / add / delete"| Notifier["expenseListProvider<br>(StreamNotifier)"]
    Notifier --> Repo["ExpenseRepository<br>(interface)"]
    Repo --> Drift["DriftExpenseRepository"]
    Drift --> DB[("SQLite")]
    DB -. "new list after every change" .-> Screen
```

### Key decisions

- **Money is stored as whole cents (`int`).** `double` cannot represent money
  exactly (`0.1 + 0.2 != 0.3`), so totals would drift. `450` means 4.50.
- **The expense date is stored as text, like `'2026-09-01'`.** It is a
  calendar day, not a moment in time. A timestamp could move to a different
  day when the user changes time zone; the text means the same day everywhere,
  and it still sorts correctly. It also makes a month a simple text range
  (`'2026-09-01'` up to, but not including, `'2026-10-01'`).
- **Categories are stored by name (`'food'`), not by position.** Reordering
  the enum can then never silently change existing rows.
- **The repository is typed as an interface.** Nothing outside the data layer
  knows Drift is behind it, and tests can replace it with a fake.
- **Adding or deleting does not update the list by hand.** Drift's query
  stream sends the new list after every change, so the database is the single
  source of truth.
- **Temporary form state stays in the widget; rules do not.** What the user
  is typing lives in the screen's `State`, while validation and parsing are
  plain functions with their own unit tests.

## Testing

129 tests, grouped by layer:

| Layer | Tests | How |
|---|---|---|
| Domain and formatting | 63 | Plain unit tests (entity equality, `copyWith`, `dateOnly`, `CalendarMonth`, money parsing and formatting) |
| Data | 17 | The real Drift repository against an in-memory SQLite database |
| Providers | 13 | A Riverpod `ProviderContainer`, with the in-memory database for the expense list |
| Form rules, labels and theme | 15 | Plain unit tests |
| Widgets | 21 | Screens, month navigation, and light/dark theme, with a fake repository |

Widget tests use a fake repository rather than SQLite: they run on a fake
clock, where Drift's stream timers can cause "Timer still pending" failures.
The fake also lets each test put the screen into a chosen state (loading,
error, empty or data).

Code reads the current time through `clockProvider` instead of calling
`DateTime.now()`, and tests pin it to a fixed date, so no test depends on
today's real date.

## Getting started

Requirements: Flutter 3.44 or newer (Dart 3.12), and an Android emulator or
iOS simulator.

```sh
git clone https://github.com/LukaMeletidi/expense-tracker-flutter.git
cd expense-tracker-flutter
flutter pub get
flutter run
```

Run the checks:

```sh
flutter analyze
flutter test
```

GitHub Actions runs the same checks, plus a formatting check, on every push
to `main` and every pull request (see `.github/workflows/ci.yml`).

The Drift code generated from the table definitions
(`lib/core/database/app_database.g.dart`) is committed, so the app runs
straight after cloning. After changing a table, regenerate it with:

```sh
dart run build_runner build
```

## Roadmap

- Edit an existing expense
- Show totals, for example for the current month
- Group the list by day

## How it was built

Built with AI-assisted pair programming (Claude Code; the project rules are in
[`CLAUDE.md`](CLAUDE.md)). Every change was planned first, reviewed, and
covered by tests before it was committed.

## Author

Luka Meletidi

- GitHub: [LukaMeletidi](https://github.com/LukaMeletidi)
- LinkedIn: [Luka Meletidi](https://www.linkedin.com/in/luka-meletidi-562010349/)

## License

[MIT](LICENSE)
