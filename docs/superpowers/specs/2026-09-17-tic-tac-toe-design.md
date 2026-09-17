# Tic Tac Toe vs. Robot — Design

Date: 2026-09-17
Status: Approved

## Goal

A Flutter tic-tac-toe game against a robot opponent, structured with clean
architecture. A landing page launches a game; finishing a game offers a
rematch.

## Scope

In scope:

- Landing page with a Play action.
- Game page: 3x3 board, turn/result status, rematch, return to landing page.
- Robot opponent that plays a random legal move.
- Unit and widget tests at every layer.

Out of scope (decided, not deferred):

- Game history, recorded replays, resuming an interrupted game.
- Persistence across app restarts.
- Difficulty levels, minimax, two-player mode, scores, animations, sound.

## Architecture

Three layers under `lib/`, with a strict dependency rule: `domain` imports only
the Dart SDK and `freezed_annotation` (a pure-Dart package — it pulls in no
Flutter dependency); `data` and `presentation` import `domain`; nothing imports
`presentation`.

```
lib/
  main.dart
  domain/
    entities/      mark.dart, board.dart, game_status.dart, game.dart
    repositories/  game_repository.dart          (interface)
    services/      robot_strategy.dart           (port)
    usecases/      start_game.dart, play_human_move.dart,
                   play_robot_move.dart
  data/
    repositories/  in_memory_game_repository.dart
    services/      random_robot_strategy.dart
  presentation/
    routing/       app_router.dart (+ generated app_router.gr.dart)
    providers/     game_providers.dart
    pages/         home_page.dart, game_page.dart
    widgets/       board_view.dart, cell_view.dart, game_status_banner.dart
```

## Domain

### Entities

- `Mark` — enum `x`, `o`.
- `Board` — immutable value object over 9 cells (`List<Mark?>`, length 9).
  - `Board.empty()`
  - `placeMark(int index, Mark mark)` returns a new `Board`; throws
    `InvalidMoveException` when `index` is outside 0..8 or the cell is taken.
  - `isFull`
  - `emptyCells` — indices of free cells.
  - `winningLine` — the winning triple of indices, or `null`. Checks the 8
    lines: 3 rows, 3 columns, 2 diagonals.
- `GameStatus` — sealed: `InProgress`, `Win(Mark winner, List<int> line)`,
  `Draw`.
- `Game` — `board`, `currentPlayer`, and `status` derived from the board.
  - `Game.start()` — empty board, `currentPlayer == Mark.x`.
  - `playAt(int index)` returns a new `Game` with the mark placed and the
    player switched; throws `InvalidMoveException` when the game is already
    over. Board-level illegality propagates from `Board.placeMark`.

The human is `Mark.x` and always moves first; the robot is `Mark.o`.

### Ports

- `GameRepository` — `Game? getCurrent()`, `void save(Game game)`.
- `RobotStrategy` — `int chooseMove(Board board)`. Contract: returns an index
  drawn from `board.emptyCells`; throws `StateError` when the board is full.

### Use cases

Each is a single-responsibility class with a `call` method.

- `StartGame` — creates `Game.start()`, saves it, returns it.
- `PlayHumanMove(int index)` — loads the current game, applies the move, saves,
  returns the new game. Throws `StateError` when no game is in progress.
- `PlayRobotMove()` — loads the current game; if its status is not
  `InProgress`, returns it unchanged; otherwise asks `RobotStrategy` for an
  index, applies it, saves, returns the new game.
`PlayHumanMove` and `PlayRobotMove` are deliberately separate so the
presentation layer can pause between them for a "Robot is thinking…" beat.
Merging them into one `PlayTurn` use case would push UI timing into the domain.

## Data

- `InMemoryGameRepository implements GameRepository` — holds a single nullable
  `Game` field. Plain getters and setters, no streams: the Riverpod notifier is
  the single source of truth for what the UI renders, and a repository stream
  would duplicate it.
- `RandomRobotStrategy implements RobotStrategy` — takes a `Random` through its
  constructor (defaulting to `Random()`), so tests can seed it. Picks uniformly
  from `board.emptyCells`.

## Presentation

### State

`GameUiState` — `Game game` and `bool robotThinking`. `GameNotifier` (a
Riverpod `Notifier<GameUiState>`) owns turn sequencing:

1. Tap on cell `i` — ignored when `robotThinking` is true, when the cell is
   taken, or when the game is over.
2. `PlayHumanMove(i)` -> emit new state.
3. If the status is still `InProgress`: emit `robotThinking: true`, wait the
   injected `robotDelayProvider` duration, run `PlayRobotMove()`, emit the
   result with `robotThinking: false`.
4. `startNewGame()` calls `StartGame` and emits a fresh state, which is what
   the rematch button uses. `gameNotifierProvider` is auto-dispose, so leaving
   the game page disposes the notifier and re-entering the route rebuilds it —
   `build()` calls `StartGame` too, which is what makes entering the game page
   always begin a new game, whatever path the user arrives by.

The delay is a provider (default 500 ms) so widget tests override it to
`Duration.zero`.

### Dependency injection

Riverpod providers wire everything: `gameRepositoryProvider`,
`robotStrategyProvider`, one provider per use case, `robotDelayProvider`, and
`gameNotifierProvider`. Tests override the leaves. `ProviderScope` wraps the
app in `main.dart`.

### Routing

`auto_route`. `AppRouter` is annotated `@AutoRouterConfig` and declares two
routes; `HomePage` and `GamePage` carry `@RoutePage()`. `app_router.gr.dart` is
generated by `build_runner` and committed. Navigation goes through
`context.router` / typed route objects rather than string paths.

### Screens

- **HomePage** — title, a short line of copy, and a **Play** button that pushes
  `GameRoute`. It holds no state of its own. Entering the game page starts a
  fresh game, because the auto-dispose notifier is rebuilt on entry rather
  than reset by the caller — so a browser Back/Forward navigation on the web
  build deals a fresh board just as the button does.
- **GamePage** — status banner, 3x3 board, and a back action returning to the
  home page. When the game is over, a **Play again** button resets the board in
  place. Status text: "Your turn", "Robot is thinking…", "You win!",
  "Robot wins!", "Draw". The winning line is highlighted.

Each cell carries a `ValueKey('cell-<index>')` so widget tests select it by
index rather than by glyph, and a matching `Semantics` label for screen
readers.

## Error handling

Illegal moves are unreachable through the UI: taken cells and the whole board
are disabled while it is not the human's turn or the game is over.
`InvalidMoveException` and the `StateError`s above are safety nets that the
tests exercise directly; no UI path catches them individually.

Anything that does escape is caught globally. `AppErrorHandler` installs
`FlutterError.onError` and `PlatformDispatcher.instance.onError`, and on the
first error presents a non-dismissible dialog — "Oops, something went wrong",
acknowledged with **Understand** — then replaces the navigation stack with
`HomeRoute`. Because `gameNotifierProvider` is auto-dispose, returning home
also discards the game that may have been corrupted.

Three details matter:

- **Release only.** `intercept` defaults to `kReleaseMode`, so debug and
  profile builds keep Flutter's red error screen and the console stack trace.
  It is supplied through `interceptAppErrorsProvider`, which widget tests
  override to exercise the release path while running in debug.
- **One dialog, not a storm.** A build error can fire every frame, so an
  in-flight apology suppresses further ones until it completes.
- **The previous handlers are preserved and still called first**, so the
  console output and `flutter_test`'s own failure reporting keep working, and
  `uninstall()` restores them when the app widget is disposed.

## Testing

Test-driven: a failing test precedes each piece of implementation.

- `Board` — placement, immutability, `emptyCells`, `isFull`, all 8 winning
  lines, rejection of out-of-range and taken cells.
- `Game` — starting state, player alternation, status transitions, rejection of
  moves after the game ends.
- Use cases — each against a fake `GameRepository` and a stub `RobotStrategy`.
- `RandomRobotStrategy` — seeded `Random`; only ever returns an empty cell;
  throws on a full board.
- `GameNotifier` — full turn cycle with a stub strategy and a zero delay:
  robot replies, taps ignored while thinking, win/draw states, rematch resets.
- Widget tests — `HomePage` navigates to the game; `GamePage` renders marks on
  tap, shows the result, and the rematch button clears the board.

## Dependencies to add

Runtime: `flutter_riverpod`, `freezed_annotation`, `auto_route`.
Dev: `build_runner`, `freezed`, `auto_route_generator`.

No `json_serializable`: nothing in this app is serialised.

Versions resolved by `flutter pub add` at implementation time.

## Models

All four models — `Board`, `GameStatus`, `Game` and `GameUiState` — are
Freezed classes, with `==`, `hashCode`, `toString` and `copyWith` generated
into committed `.freezed.dart` part files. `Mark` stays a plain enum and
`InvalidMoveException` a plain exception; neither is a model.

`GameStatus` is a Freezed union whose case classes are named `InProgress`,
`Win` and `Draw`, so the presentation layer pattern-matches on those names
directly.

Collection fields — `Board.cells` and `Win.line` — compare by value, because
Freezed's generated equality uses `DeepCollectionEquality`.

`Board` uses the plain Freezed constructor, so it does not defensively copy
the list it is given: mutating that list afterwards is visible through the
board. Reading `Board.cells` yields an unmodifiable view, so writing through
the getter still throws. This trade-off was chosen deliberately in favour of
the idiomatic single-constructor shape.
