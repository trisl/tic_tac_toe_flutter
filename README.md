# Tic Tac Toe

A small Flutter game: play a round of tic tac toe against a robot opponent.

Launch a game from the landing page, take turns on a 3×3 board, and rematch
when it ends. You play `X` and always move first; the robot plays `O` and
answers with a random legal move after a short pause. Nothing is persisted, closing the app forgets the game.

Built as a clean-architecture reference: the game rules are pure Dart with no
Flutter in sight, and the UI is a thin layer over them.

## Getting started

Requires Flutter 3.47+ (Dart SDK `^3.13.3`).

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Runs on Android, iOS, web, macOS, Linux and Windows.

## Code generation

Routes (`auto_route`) and models (`freezed`) are generated. The `.gr.dart` and
`.freezed.dart` files are committed, so a fresh clone builds without running
the generator — but re-run it after touching a model or a route:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Checks

```bash
flutter test                                    # 104 tests
flutter test --coverage                         # 100% line coverage
dart analyze                                    # lints, incl. riverpod_lint
dart format --set-exit-if-changed lib test      # page width 80
```

Generated files are excluded from both coverage and analysis.

> **Use `dart analyze`, not `flutter analyze`.** `riverpod_lint` is a native
> analyzer plugin, and `flutter analyze` does not surface plugin diagnostics in
> this Flutter version — it reports "No issues found!" on code that
> `dart analyze` rejects. Run `dart analyze` in CI.

`analysis_options.yaml` is strict on purpose: `strict-casts`,
`strict-inference` and `strict-raw-types` are on, unused imports/locals/fields
and dead code are promoted from warnings to **errors**, and a dozen lint rules
sit on top of `flutter_lints`. Every setting is satisfied by the code as it
stands — the file also records which rules were deliberately *rejected*, and
why.

## Architecture

Three layers with a strict dependency rule: **domain** knows nothing about the
others, **data** and **presentation** depend on domain, and nothing depends on
presentation.

```
lib/
  domain/        Pure Dart. Entities (Board, Game, GameStatus, Mark), the
                 GameRepository and RobotStrategy ports, and three use cases.
                 No Flutter, no Riverpod, no routing.
  data/          The adapters behind those ports: an in-memory repository and
                 a random-move robot.
  presentation/  Riverpod providers and GameNotifier, the board widgets, the
                 two pages, and the auto_route router.
```

The robot sits behind a `RobotStrategy` port, so swapping the random player for
a minimax one means adding a class and changing a single provider.

`GameNotifier` owns the turn cycle — it applies your move, shows a "thinking"
pause, then plays the robot's reply. That pause lives in the presentation layer
on purpose, so UI timing never leaks into the domain.

`Game.status` is derived from the board rather than stored, so it cannot drift
out of sync with it.

## Stack

| | Package | Version |
|---|---|---|
| State & DI | `flutter_riverpod` | `^3.4.3` |
| Routing | `auto_route` | `^11.1.0` |
| | `auto_route_generator` (dev) | `^10.6.0` |
| Models | `freezed_annotation` | `^3.1.0` |
| | `freezed` (dev) | `^4.0.1` |
| Code generation | `build_runner` (dev) | `^2.16.1` |
| Lints | `flutter_lints` (dev) | `^6.0.0` |
| | `riverpod_lint` (dev) | `^3.1.9` |

## Design notes

Longer write-ups live in [`docs/superpowers/`](docs/superpowers/): the
[design spec](docs/superpowers/specs/2026-09-17-tic-tac-toe-design.md) covers
the architecture and the decisions behind it, and the
[implementation plan](docs/superpowers/plans/2026-09-17-tic-tac-toe.md) records
how it was built, task by task.

**Errors are handled globally.** Anything that escapes the widget tree shows a
single "Oops, something went wrong" dialog and returns the user to the home
page. This is **release-only** — debug and profile builds keep Flutter's red
error screen and the console stack trace, which is what you want while
developing. To see the user-facing behaviour in a test, override
`interceptAppErrorsProvider` with `true`.

Two more things worth knowing before you change something:

- **`gameNotifierProvider` is auto-dispose.** Leaving the game page ends the
  game, so re-entering the route always deals a fresh board. Don't add a manual
  reset before navigating — that was the old design and it left a stale board
  reachable via the browser's Forward button.
- **`Board` does not copy the list it is constructed from.** Reading
  `board.cells` gives an unmodifiable view, but mutating the original list is
  visible through the board. Pass it a list nobody else holds.
