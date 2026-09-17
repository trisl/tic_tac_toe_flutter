# Tic Tac Toe vs. Robot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Flutter tic-tac-toe game against a robot that plays random legal moves, with a landing page that launches a game and a rematch button when the game ends.

**Architecture:** Three layers under `lib/` — `domain` (pure Dart entities, ports, use cases), `data` (in-memory repository, random robot strategy), `presentation` (Riverpod notifier, widgets, auto_route pages). `domain` imports only the Dart SDK and `equatable`; `data` and `presentation` import `domain`; nothing imports `presentation`. State lives in a Riverpod `Notifier` that sequences the human turn and the robot's reply.

**Tech Stack:** Flutter 3.47.4 / Dart 3.13.3, `flutter_riverpod` (state + DI), `equatable` (value equality), `auto_route` + `build_runner` (typed routing), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-17-tic-tac-toe-design.md`

## Global Constraints

- **No git.** The user has explicitly asked that version control be left alone. Do NOT run `git init`, `git add`, or `git commit` at any point. Each task ends with a test run and an analyzer run instead of a commit.
- Dart SDK constraint stays `^3.13.3`; do not edit the `environment` block in `pubspec.yaml`.
- Dependency rule: nothing under `lib/domain/` may import `package:flutter/...`, `package:flutter_riverpod/...`, `package:auto_route/...`, or anything from `lib/data/` or `lib/presentation/`. `equatable` and `dart:` libraries are allowed.
- The human player is `Mark.x` and always moves first. The robot is `Mark.o`.
- Nothing is persisted. There is no game history and no resume.
- Exact UI copy (used verbatim in tests): `Tic Tac Toe`, `Play a round against the robot.`, `Play`, `Your turn`, `Robot is thinking…` (note: single-character ellipsis `…`), `You win!`, `Robot wins!`, `Draw`, `Play again`.
- Every task ends green: `flutter test` passes and `flutter analyze` reports no issues.
- Test files mirror the `lib/` path under `test/` (e.g. `lib/domain/entities/board.dart` → `test/domain/entities/board_test.dart`).

---

### Task 1: Domain entities — `Mark` and `Board`

**Files:**
- Modify: `pubspec.yaml` (add `equatable`)
- Create: `lib/domain/entities/mark.dart`
- Create: `lib/domain/exceptions/invalid_move_exception.dart`
- Create: `lib/domain/entities/board.dart`
- Test: `test/domain/entities/board_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum Mark { x, o }` with `Mark get opponent`.
  - `class InvalidMoveException implements Exception` with `const InvalidMoveException(String message)` and a `final String message`.
  - `class Board extends Equatable` with: `Board(List<Mark?> cells)` (not const — the length assert reads `cells.length`, which is illegal in a constant expression — and it wraps the list in `List.unmodifiable`); `factory Board.empty()`; `static const int size = 9`; `static const List<List<int>> lines`; `final List<Mark?> cells`; `Mark? cellAt(int index)`; `bool isEmptyAt(int index)`; `List<int> get emptyCells`; `bool get isFull`; `List<int>? get winningLine`; `Board placeMark(int index, Mark mark)`.

- [ ] **Step 1: Add the `equatable` dependency**

```bash
flutter pub add equatable
```

- [ ] **Step 2: Write the failing test**

Create `test/domain/entities/board_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/domain/exceptions/invalid_move_exception.dart';

/// Builds a board from a 9-character string: 'x', 'o' or '.' per cell.
Board boardFrom(String pattern) {
  expect(pattern.length, 9, reason: 'a board pattern must have 9 cells');
  return Board([
    for (final char in pattern.split(''))
      switch (char) {
        'x' => Mark.x,
        'o' => Mark.o,
        _ => null,
      },
  ]);
}

void main() {
  group('Mark', () {
    test('opponent flips the mark', () {
      expect(Mark.x.opponent, Mark.o);
      expect(Mark.o.opponent, Mark.x);
    });
  });

  group('Board.empty', () {
    test('has nine empty cells', () {
      final board = Board.empty();

      expect(board.cells.length, 9);
      expect(board.emptyCells, [0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(board.isFull, isFalse);
      expect(board.winningLine, isNull);
    });
  });

  group('placeMark', () {
    test('returns a new board with the mark placed', () {
      final board = Board.empty().placeMark(4, Mark.x);

      expect(board.cellAt(4), Mark.x);
      expect(board.isEmptyAt(4), isFalse);
      expect(board.emptyCells, [0, 1, 2, 3, 5, 6, 7, 8]);
    });

    test('leaves the original board untouched', () {
      final original = Board.empty();

      original.placeMark(0, Mark.x);

      expect(original.cellAt(0), isNull);
      expect(original.emptyCells.length, 9);
    });

    test('cannot be mutated through the cells it was built from', () {
      final cells = List<Mark?>.filled(9, null);
      final board = Board(cells);

      cells[0] = Mark.x;

      expect(board.cellAt(0), isNull);
      expect(() => board.cells[1] = Mark.o, throwsUnsupportedError);
    });

    test('rejects a cell that is already taken', () {
      final board = Board.empty().placeMark(0, Mark.x);

      expect(
        () => board.placeMark(0, Mark.o),
        throwsA(isA<InvalidMoveException>()),
      );
    });

    test('rejects an index outside 0..8', () {
      expect(
        () => Board.empty().placeMark(-1, Mark.x),
        throwsA(isA<InvalidMoveException>()),
      );
      expect(
        () => Board.empty().placeMark(9, Mark.x),
        throwsA(isA<InvalidMoveException>()),
      );
    });
  });

  group('winningLine', () {
    test('finds each of the three rows', () {
      expect(boardFrom('xxx.o.o..').winningLine, [0, 1, 2]);
      expect(boardFrom('o.oxxx...').winningLine, [3, 4, 5]);
      expect(boardFrom('.oo.x.xxx').winningLine, [6, 7, 8]);
    });

    test('finds each of the three columns', () {
      expect(boardFrom('x.ox.ox..').winningLine, [0, 3, 6]);
      expect(boardFrom('ox.ox..x.').winningLine, [1, 4, 7]);
      expect(boardFrom('o.xo.x..x').winningLine, [2, 5, 8]);
    });

    test('finds both diagonals', () {
      expect(boardFrom('xo.ox...x').winningLine, [0, 4, 8]);
      expect(boardFrom('o.x.x.xo.').winningLine, [2, 4, 6]);
    });

    test('works for the robot too', () {
      expect(boardFrom('ooox.x.x.').winningLine, [0, 1, 2]);
    });

    test('is null when no line is complete', () {
      expect(boardFrom('xoxxoxoxo').winningLine, isNull);
    });
  });

  group('isFull', () {
    test('is true only when every cell is taken', () {
      expect(boardFrom('xoxxoxoxo').isFull, isTrue);
      expect(boardFrom('xoxxoxox.').isFull, isFalse);
    });
  });

  group('equality', () {
    test('two boards with the same cells are equal', () {
      expect(boardFrom('xo.......'), boardFrom('xo.......'));
      expect(boardFrom('xo.......'), isNot(boardFrom('ox.......')));
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/domain/entities/board_test.dart`
Expected: FAIL — the analyzer cannot resolve `board.dart`, `mark.dart` or `invalid_move_exception.dart`.

- [ ] **Step 4: Write the implementation**

Create `lib/domain/entities/mark.dart`:

```dart
/// The two marks that can occupy a cell. The human plays [x], the robot [o].
enum Mark {
  x,
  o;

  Mark get opponent => this == Mark.x ? Mark.o : Mark.x;
}
```

Create `lib/domain/exceptions/invalid_move_exception.dart`:

```dart
/// Thrown when a move is not legal for the current board or game.
///
/// The UI makes illegal moves unreachable, so this is a safety net rather
/// than a control-flow path.
class InvalidMoveException implements Exception {
  const InvalidMoveException(this.message);

  final String message;

  @override
  String toString() => 'InvalidMoveException: $message';
}
```

Create `lib/domain/entities/board.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../exceptions/invalid_move_exception.dart';
import 'mark.dart';

/// An immutable 3x3 board, stored as nine cells in row-major order.
class Board extends Equatable {
  // `const` is impossible here: the assert reads `cells.length`, and property
  // access is illegal in a constant expression. The constructor wraps the
  // caller's list so the board can never be mutated behind its own back.
  // ignore: prefer_const_constructors_in_immutables
  Board(List<Mark?> cells)
    : cells = List<Mark?>.unmodifiable(cells),
      assert(cells.length == size, 'a board has 9 cells');

  factory Board.empty() => Board(List<Mark?>.filled(9, null));

  static const int size = 9;

  /// The eight lines that win a game: three rows, three columns, two diagonals.
  static const List<List<int>> lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  final List<Mark?> cells;

  Mark? cellAt(int index) => cells[index];

  bool isEmptyAt(int index) => cells[index] == null;

  List<int> get emptyCells => [
    for (var index = 0; index < size; index++)
      if (cells[index] == null) index,
  ];

  bool get isFull => emptyCells.isEmpty;

  /// The indices of the first complete line, or `null` when there is none.
  List<int>? get winningLine {
    for (final line in lines) {
      final mark = cells[line[0]];
      if (mark != null && cells[line[1]] == mark && cells[line[2]] == mark) {
        return line;
      }
    }
    return null;
  }

  /// Returns a new board with [mark] placed at [index].
  ///
  /// Throws [InvalidMoveException] when [index] is out of range or taken.
  Board placeMark(int index, Mark mark) {
    if (index < 0 || index >= size) {
      throw InvalidMoveException('Cell index $index is outside 0..8.');
    }
    if (cells[index] != null) {
      throw InvalidMoveException('Cell $index is already taken.');
    }
    final next = List<Mark?>.of(cells);
    next[index] = mark;
    return Board(next);
  }

  @override
  List<Object?> get props => cells;
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/domain/entities/board_test.dart`
Expected: PASS — all tests green.

- [ ] **Step 6: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

---

### Task 2: Domain entities — `GameStatus` and `Game`

**Files:**
- Create: `lib/domain/entities/game_status.dart`
- Create: `lib/domain/entities/game.dart`
- Test: `test/domain/entities/game_test.dart`

**Interfaces:**
- Consumes: `Board`, `Mark`, `InvalidMoveException` from Task 1.
- Produces:
  - `sealed class GameStatus extends Equatable` with subclasses `InProgress` (`const InProgress()`), `Win` (`const Win(Mark winner, List<int> line)`, fields `winner` and `line`), and `Draw` (`const Draw()`).
  - `class Game extends Equatable` with: `const Game({required Board board, required Mark currentPlayer})`; `factory Game.start()`; `final Board board`; `final Mark currentPlayer`; `GameStatus get status`; `bool get isOver`; `Game playAt(int index)`.

- [ ] **Step 1: Write the failing test**

Create `test/domain/entities/game_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game_status.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/domain/exceptions/invalid_move_exception.dart';

/// Plays [indices] in order, alternating players from the starting position.
Game playAll(List<int> indices) {
  var game = Game.start();
  for (final index in indices) {
    game = game.playAt(index);
  }
  return game;
}

void main() {
  group('Game.start', () {
    test('begins with an empty board and the human to move', () {
      final game = Game.start();

      expect(game.board, Board.empty());
      expect(game.currentPlayer, Mark.x);
      expect(game.status, const InProgress());
      expect(game.isOver, isFalse);
    });
  });

  group('playAt', () {
    test('places the current mark and hands over the turn', () {
      final game = Game.start().playAt(4);

      expect(game.board.cellAt(4), Mark.x);
      expect(game.currentPlayer, Mark.o);
    });

    test('alternates players across moves', () {
      final game = playAll([0, 1, 2]);

      expect(game.board.cellAt(0), Mark.x);
      expect(game.board.cellAt(1), Mark.o);
      expect(game.board.cellAt(2), Mark.x);
      expect(game.currentPlayer, Mark.o);
    });

    test('leaves the previous game untouched', () {
      final first = Game.start();

      first.playAt(0);

      expect(first.board.cellAt(0), isNull);
      expect(first.currentPlayer, Mark.x);
    });

    test('rejects a taken cell', () {
      final game = Game.start().playAt(0);

      expect(() => game.playAt(0), throwsA(isA<InvalidMoveException>()));
    });

    test('rejects any move once the game is over', () {
      // x: 0, 1, 2 wins; o: 3, 4.
      final game = playAll([0, 3, 1, 4, 2]);

      expect(game.isOver, isTrue);
      expect(() => game.playAt(5), throwsA(isA<InvalidMoveException>()));
    });
  });

  group('status', () {
    test('reports a human win with the winning line', () {
      final game = playAll([0, 3, 1, 4, 2]);

      expect(game.status, const Win(Mark.x, [0, 1, 2]));
    });

    test('reports a robot win', () {
      // x: 0, 1, 8; o: 3, 4, 5 wins.
      final game = playAll([0, 3, 1, 4, 8, 5]);

      expect(game.status, const Win(Mark.o, [3, 4, 5]));
      expect(game.isOver, isTrue);
    });

    test('reports a draw when the board fills with no line', () {
      // Final board: x o x / x o o / o x x
      final game = playAll([0, 1, 2, 4, 3, 5, 7, 6, 8]);

      expect(game.board.isFull, isTrue);
      expect(game.status, const Draw());
      expect(game.isOver, isTrue);
    });

    test('is in progress while the board is open and unwon', () {
      final game = playAll([0, 4]);

      expect(game.status, const InProgress());
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/entities/game_test.dart`
Expected: FAIL — `game.dart` and `game_status.dart` do not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/domain/entities/game_status.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'mark.dart';

/// The outcome of a game at a point in time.
sealed class GameStatus extends Equatable {
  const GameStatus();

  @override
  List<Object?> get props => const [];
}

class InProgress extends GameStatus {
  const InProgress();
}

class Win extends GameStatus {
  const Win(this.winner, this.line);

  final Mark winner;

  /// The three cell indices that completed the line.
  final List<int> line;

  @override
  List<Object?> get props => [winner, line];
}

class Draw extends GameStatus {
  const Draw();
}
```

Create `lib/domain/entities/game.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../exceptions/invalid_move_exception.dart';
import 'board.dart';
import 'game_status.dart';
import 'mark.dart';

/// A game in progress: the board plus whose turn it is.
///
/// The status is derived from the board rather than stored, so it can never
/// drift out of sync with it.
class Game extends Equatable {
  const Game({required this.board, required this.currentPlayer});

  factory Game.start() => Game(board: Board.empty(), currentPlayer: Mark.x);

  final Board board;
  final Mark currentPlayer;

  GameStatus get status {
    final line = board.winningLine;
    if (line != null) {
      return Win(board.cellAt(line.first)!, line);
    }
    if (board.isFull) {
      return const Draw();
    }
    return const InProgress();
  }

  bool get isOver => status is! InProgress;

  /// Returns the game that follows from the current player taking [index].
  ///
  /// Throws [InvalidMoveException] when the game is over or the cell is not
  /// playable.
  Game playAt(int index) {
    if (isOver) {
      throw const InvalidMoveException('The game is already over.');
    }
    return Game(
      board: board.placeMark(index, currentPlayer),
      currentPlayer: currentPlayer.opponent,
    );
  }

  @override
  List<Object?> get props => [board, currentPlayer];
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/domain/entities/game_test.dart`
Expected: PASS

- [ ] **Step 5: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

---

### Task 3: Domain ports and use cases

**Files:**
- Create: `lib/domain/repositories/game_repository.dart`
- Create: `lib/domain/services/robot_strategy.dart`
- Create: `lib/domain/usecases/start_game.dart`
- Create: `lib/domain/usecases/play_human_move.dart`
- Create: `lib/domain/usecases/play_robot_move.dart`
- Create: `test/helpers/fakes.dart`
- Test: `test/domain/usecases/usecases_test.dart`

**Interfaces:**
- Consumes: `Game`, `Board`, `Mark` from Tasks 1-2.
- Produces:
  - `abstract interface class GameRepository` with `Game? getCurrent()` and `void save(Game game)`.
  - `abstract interface class RobotStrategy` with `int chooseMove(Board board)`.
  - `class StartGame` — `const StartGame(GameRepository repository)`, `Game call()`.
  - `class PlayHumanMove` — `const PlayHumanMove(GameRepository repository)`, `Game call(int index)`.
  - `class PlayRobotMove` — `const PlayRobotMove(GameRepository repository, RobotStrategy strategy)`, `Game call()`.
  - Test helpers in `test/helpers/fakes.dart`: `class FakeGameRepository implements GameRepository` (fields `Game? current`, `int saveCount`) and `class StubRobotStrategy implements RobotStrategy` (`StubRobotStrategy(List<int> moves)`, returns the queued moves in order).

- [ ] **Step 1: Write the failing test**

Create `test/helpers/fakes.dart`:

```dart
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/repositories/game_repository.dart';
import 'package:tic_tac_toe_v2_flutter/domain/services/robot_strategy.dart';

/// An in-test double that exposes what was saved.
class FakeGameRepository implements GameRepository {
  FakeGameRepository([this.current]);

  Game? current;
  int saveCount = 0;

  @override
  Game? getCurrent() => current;

  @override
  void save(Game game) {
    current = game;
    saveCount++;
  }
}

/// Returns the queued moves in order, so robot behaviour is deterministic.
class StubRobotStrategy implements RobotStrategy {
  StubRobotStrategy(this.moves);

  final List<int> moves;
  int calls = 0;

  @override
  int chooseMove(Board board) {
    if (calls >= moves.length) {
      throw StateError('StubRobotStrategy ran out of queued moves.');
    }
    return moves[calls++];
  }
}
```

Create `test/domain/usecases/usecases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game_status.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/domain/usecases/play_human_move.dart';
import 'package:tic_tac_toe_v2_flutter/domain/usecases/play_robot_move.dart';
import 'package:tic_tac_toe_v2_flutter/domain/usecases/start_game.dart';

import '../../helpers/fakes.dart';

void main() {
  group('StartGame', () {
    test('returns a fresh game and saves it', () {
      final repository = FakeGameRepository();

      final game = StartGame(repository)();

      expect(game, Game.start());
      expect(repository.current, Game.start());
      expect(repository.saveCount, 1);
    });

    test('replaces a game already in progress', () {
      final repository = FakeGameRepository(Game.start().playAt(0));

      final game = StartGame(repository)();

      expect(game.board.emptyCells.length, 9);
      expect(game.currentPlayer, Mark.x);
    });
  });

  group('PlayHumanMove', () {
    test('applies the move and saves the result', () {
      final repository = FakeGameRepository(Game.start());

      final game = PlayHumanMove(repository)(4);

      expect(game.board.cellAt(4), Mark.x);
      expect(repository.current, game);
      expect(repository.saveCount, 1);
    });

    test('throws when no game is in progress', () {
      final repository = FakeGameRepository();

      expect(() => PlayHumanMove(repository)(0), throwsStateError);
    });
  });

  group('PlayRobotMove', () {
    test('plays the move the strategy chose and saves it', () {
      final repository = FakeGameRepository(Game.start().playAt(0));
      final strategy = StubRobotStrategy([4]);

      final game = PlayRobotMove(repository, strategy)();

      expect(game.board.cellAt(4), Mark.o);
      expect(game.currentPlayer, Mark.x);
      expect(repository.current, game);
    });

    test('does nothing once the game is over', () {
      // x has already won with 0, 1, 2.
      var finished = Game.start();
      for (final index in [0, 3, 1, 4, 2]) {
        finished = finished.playAt(index);
      }
      final repository = FakeGameRepository(finished);
      final strategy = StubRobotStrategy([5]);

      final game = PlayRobotMove(repository, strategy)();

      expect(game, finished);
      expect(game.status, const Win(Mark.x, [0, 1, 2]));
      expect(strategy.calls, 0);
      expect(repository.saveCount, 0);
    });

    test('throws when no game is in progress', () {
      final repository = FakeGameRepository();

      expect(
        () => PlayRobotMove(repository, StubRobotStrategy([0]))(),
        throwsStateError,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/usecases/usecases_test.dart`
Expected: FAIL — the repository, strategy and use case files do not exist.

- [ ] **Step 3: Write the ports**

Create `lib/domain/repositories/game_repository.dart`:

```dart
import '../entities/game.dart';

/// Stores the game currently being played.
abstract interface class GameRepository {
  /// The game in progress, or `null` when none has been started.
  Game? getCurrent();

  void save(Game game);
}
```

Create `lib/domain/services/robot_strategy.dart`:

```dart
import '../entities/board.dart';

/// Chooses the robot's move.
///
/// Implementations must return an index drawn from [Board.emptyCells], and
/// must throw a [StateError] when the board is full.
abstract interface class RobotStrategy {
  int chooseMove(Board board);
}
```

- [ ] **Step 4: Write the use cases**

Create `lib/domain/usecases/start_game.dart`:

```dart
import '../entities/game.dart';
import '../repositories/game_repository.dart';

/// Begins a new game, discarding any game already in progress.
class StartGame {
  const StartGame(this._repository);

  final GameRepository _repository;

  Game call() {
    final game = Game.start();
    _repository.save(game);
    return game;
  }
}
```

Create `lib/domain/usecases/play_human_move.dart`:

```dart
import '../entities/game.dart';
import '../repositories/game_repository.dart';

/// Applies the human player's move to the game in progress.
class PlayHumanMove {
  const PlayHumanMove(this._repository);

  final GameRepository _repository;

  Game call(int index) {
    final current = _repository.getCurrent();
    if (current == null) {
      throw StateError('No game in progress.');
    }
    final next = current.playAt(index);
    _repository.save(next);
    return next;
  }
}
```

Create `lib/domain/usecases/play_robot_move.dart`:

```dart
import '../entities/game.dart';
import '../repositories/game_repository.dart';
import '../services/robot_strategy.dart';

/// Lets the robot answer the human's move.
///
/// Returns the game unchanged when it has already ended, so callers do not
/// have to re-check the status themselves.
class PlayRobotMove {
  const PlayRobotMove(this._repository, this._strategy);

  final GameRepository _repository;
  final RobotStrategy _strategy;

  Game call() {
    final current = _repository.getCurrent();
    if (current == null) {
      throw StateError('No game in progress.');
    }
    if (current.isOver) {
      return current;
    }
    final next = current.playAt(_strategy.chooseMove(current.board));
    _repository.save(next);
    return next;
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/domain/usecases/usecases_test.dart`
Expected: PASS

- [ ] **Step 6: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

---

### Task 4: Data layer — in-memory repository and random robot

**Files:**
- Create: `lib/data/repositories/in_memory_game_repository.dart`
- Create: `lib/data/services/random_robot_strategy.dart`
- Test: `test/data/repositories/in_memory_game_repository_test.dart`
- Test: `test/data/services/random_robot_strategy_test.dart`

**Interfaces:**
- Consumes: `GameRepository`, `RobotStrategy`, `Game`, `Board`, `Mark` from Tasks 1-3.
- Produces:
  - `class InMemoryGameRepository implements GameRepository` — default constructor, no arguments.
  - `class RandomRobotStrategy implements RobotStrategy` — `RandomRobotStrategy([Random? random])`.

- [ ] **Step 1: Write the failing tests**

Create `test/data/repositories/in_memory_game_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/data/repositories/in_memory_game_repository.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';

void main() {
  group('InMemoryGameRepository', () {
    test('has no game before one is saved', () {
      expect(InMemoryGameRepository().getCurrent(), isNull);
    });

    test('returns the game that was saved', () {
      final repository = InMemoryGameRepository();
      final game = Game.start();

      repository.save(game);

      expect(repository.getCurrent(), game);
    });

    test('keeps only the most recent game', () {
      final repository = InMemoryGameRepository()..save(Game.start());

      repository.save(Game.start().playAt(0));

      expect(repository.getCurrent()!.board.cellAt(0), Mark.x);
    });

    test('two instances do not share state', () {
      final first = InMemoryGameRepository()..save(Game.start());
      final second = InMemoryGameRepository();

      expect(first.getCurrent(), isNotNull);
      expect(second.getCurrent(), isNull);
    });
  });
}
```

Create `test/data/services/random_robot_strategy_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/data/services/random_robot_strategy.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';

void main() {
  group('RandomRobotStrategy', () {
    test('only ever picks an empty cell', () {
      final strategy = RandomRobotStrategy(Random(1));
      final board = Board.empty()
          .placeMark(0, Mark.x)
          .placeMark(1, Mark.o)
          .placeMark(2, Mark.x);

      for (var attempt = 0; attempt < 100; attempt++) {
        expect(board.emptyCells, contains(strategy.chooseMove(board)));
      }
    });

    test('takes the last free cell when only one is left', () {
      final strategy = RandomRobotStrategy(Random(7));
      var board = Board.empty();
      for (final index in [0, 1, 2, 3, 4, 5, 6, 7]) {
        board = board.placeMark(index, Mark.x);
      }

      expect(strategy.chooseMove(board), 8);
    });

    test('is deterministic for a given seed', () {
      final first = RandomRobotStrategy(Random(42)).chooseMove(Board.empty());
      final second = RandomRobotStrategy(Random(42)).chooseMove(Board.empty());

      expect(first, second);
    });

    test('spreads its choices over the free cells', () {
      final strategy = RandomRobotStrategy(Random(3));
      final chosen = <int>{};

      for (var attempt = 0; attempt < 200; attempt++) {
        chosen.add(strategy.chooseMove(Board.empty()));
      }

      expect(chosen.length, greaterThan(1));
    });

    test('throws when the board is full', () {
      var board = Board.empty();
      for (var index = 0; index < 9; index++) {
        board = board.placeMark(index, Mark.x);
      }

      expect(
        () => RandomRobotStrategy(Random(0)).chooseMove(board),
        throwsStateError,
      );
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/data`
Expected: FAIL — neither data-layer file exists.

- [ ] **Step 3: Write the implementation**

Create `lib/data/repositories/in_memory_game_repository.dart`:

```dart
import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';

/// Holds the current game for the lifetime of the app.
///
/// Nothing is persisted: closing the app discards the game, which is what the
/// product asks for.
class InMemoryGameRepository implements GameRepository {
  Game? _game;

  @override
  Game? getCurrent() => _game;

  @override
  void save(Game game) => _game = game;
}
```

Create `lib/data/services/random_robot_strategy.dart`:

```dart
import 'dart:math';

import '../../domain/entities/board.dart';
import '../../domain/services/robot_strategy.dart';

/// Picks uniformly among the free cells.
///
/// The [Random] is injected so tests can seed it and get a fixed sequence.
class RandomRobotStrategy implements RobotStrategy {
  RandomRobotStrategy([Random? random]) : _random = random ?? Random();

  final Random _random;

  @override
  int chooseMove(Board board) {
    final free = board.emptyCells;
    if (free.isEmpty) {
      throw StateError('The board is full, the robot has no move to make.');
    }
    return free[_random.nextInt(free.length)];
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/data`
Expected: PASS

- [ ] **Step 5: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

---

### Task 5: Presentation state — providers and `GameNotifier`

**Files:**
- Modify: `pubspec.yaml` (add `flutter_riverpod`)
- Create: `lib/presentation/providers/game_ui_state.dart`
- Create: `lib/presentation/providers/game_notifier.dart`
- Create: `lib/presentation/providers/game_providers.dart`
- Test: `test/presentation/providers/game_notifier_test.dart`

**Interfaces:**
- Consumes: the use cases from Task 3, the implementations from Task 4, `StubRobotStrategy` from `test/helpers/fakes.dart`.
- Produces:
  - `class GameUiState extends Equatable` — `const GameUiState({required Game game, bool robotThinking = false})`, fields `game` and `robotThinking`, `bool get canPlay`, `GameUiState withRobotThinking(bool value)`.
  - `class GameNotifier extends Notifier<GameUiState>` — `GameUiState build()`, `Future<void> playAt(int index)`, `void startNewGame()`.
  - Providers in `game_providers.dart`: `gameRepositoryProvider` (`Provider<GameRepository>`), `robotStrategyProvider` (`Provider<RobotStrategy>`), `startGameProvider` (`Provider<StartGame>`), `playHumanMoveProvider` (`Provider<PlayHumanMove>`), `playRobotMoveProvider` (`Provider<PlayRobotMove>`), `robotDelayProvider` (`Provider<Duration>`, default 500 ms), `gameNotifierProvider` (`NotifierProvider<GameNotifier, GameUiState>`).

- [ ] **Step 1: Add the `flutter_riverpod` dependency**

```bash
flutter pub add flutter_riverpod
```

- [ ] **Step 2: Write the failing test**

Create `test/presentation/providers/game_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game_status.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_notifier.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_providers.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_ui_state.dart';

import '../../helpers/fakes.dart';

/// A container wired with a deterministic robot and no thinking delay.
ProviderContainer containerWith(List<int> robotMoves) {
  final container = ProviderContainer(
    overrides: [
      robotStrategyProvider.overrideWithValue(
        StubRobotStrategy(robotMoves),
      ),
      robotDelayProvider.overrideWithValue(Duration.zero),
    ],
  );
  addTearDown(container.dispose);
  // An auto-dispose provider needs a subscriber to stay alive across awaits.
  // In the app that subscriber is GamePage's `ref.watch`; here it is this
  // listener. Without it the notifier disposes mid-turn and every await
  // throws "Cannot use the Ref after it has been disposed".
  container.listen(gameNotifierProvider, (previous, next) {});
  return container;
}

void main() {
  group('GameNotifier', () {
    test('starts on an empty board with the human to move', () {
      final container = containerWith([]);

      final state = container.read(gameNotifierProvider);

      expect(state.game.board.emptyCells.length, 9);
      expect(state.game.currentPlayer, Mark.x);
      expect(state.robotThinking, isFalse);
      expect(state.canPlay, isTrue);
    });

    test('plays the human move and then the robot reply', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);

      await notifier.playAt(0);

      final state = container.read(gameNotifierProvider);
      expect(state.game.board.cellAt(0), Mark.x);
      expect(state.game.board.cellAt(4), Mark.o);
      expect(state.game.currentPlayer, Mark.x);
      expect(state.robotThinking, isFalse);
    });

    test('flags robotThinking between the two moves', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);

      // `playAt` runs synchronously up to its first await, so the flag is
      // already set by the time it hands back the future — no sleeping, and
      // therefore nothing for a loaded machine to make flaky.
      final pending = notifier.playAt(0);

      expect(container.read(gameNotifierProvider).robotThinking, isTrue);
      expect(container.read(gameNotifierProvider).canPlay, isFalse);

      await pending;

      expect(container.read(gameNotifierProvider).robotThinking, isFalse);
    });

    test('a new game started mid-turn is untouched by the pending robot move', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);

      final pending = notifier.playAt(0);
      notifier.startNewGame();
      await pending;

      final state = container.read(gameNotifierProvider);
      expect(state.game.board.emptyCells.length, 9);
      expect(state.game.currentPlayer, Mark.x);
      expect(state.robotThinking, isFalse);
    });

    test('ignores a tap on a cell that is already taken', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.playAt(0);

      await notifier.playAt(4);

      expect(container.read(gameNotifierProvider).game.board.cellAt(4), Mark.o);
    });

    test('lets the human win without giving the robot another move', () async {
      // Human takes 0, 1, 2; the robot answers 3 then 4 and never moves again.
      final container = containerWith([3, 4]);
      final notifier = container.read(gameNotifierProvider.notifier);

      await notifier.playAt(0);
      await notifier.playAt(1);
      await notifier.playAt(2);

      final state = container.read(gameNotifierProvider);
      expect(state.game.status, const Win(Mark.x, [0, 1, 2]));
      expect(state.canPlay, isFalse);
    });

    test('ignores taps once the game is over', () async {
      final container = containerWith([3, 4]);
      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.playAt(0);
      await notifier.playAt(1);
      await notifier.playAt(2);

      await notifier.playAt(5);

      expect(container.read(gameNotifierProvider).game.board.cellAt(5), isNull);
    });

    test('startNewGame clears the board', () async {
      final container = containerWith([4]);
      final notifier = container.read(gameNotifierProvider.notifier);
      await notifier.playAt(0);

      notifier.startNewGame();

      final state = container.read(gameNotifierProvider);
      expect(state.game.board.emptyCells.length, 9);
      expect(state.game.currentPlayer, Mark.x);
      expect(state.robotThinking, isFalse);
      expect(state.game.status, const InProgress());
    });
  });

  group('GameUiState', () {
    test('cannot play while the robot is thinking', () {
      final container = containerWith([]);
      final state = container.read(gameNotifierProvider);

      expect(state.withRobotThinking(true).canPlay, isFalse);
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/presentation/providers/game_notifier_test.dart`
Expected: FAIL — the provider and notifier files do not exist.

- [ ] **Step 4: Write the state class**

Create `lib/presentation/providers/game_ui_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/game.dart';

/// Everything the game screen needs to render one frame.
class GameUiState extends Equatable {
  const GameUiState({required this.game, this.robotThinking = false});

  final Game game;

  /// True between the human's move and the robot's reply.
  final bool robotThinking;

  /// Whether a tap on an empty cell should be accepted.
  bool get canPlay => !robotThinking && !game.isOver;

  /// Returns this state with the thinking flag flipped.
  GameUiState withRobotThinking(bool value) =>
      GameUiState(game: game, robotThinking: value);

  @override
  List<Object?> get props => [game, robotThinking];
}
```

- [ ] **Step 5: Write the notifier**

Create `lib/presentation/providers/game_notifier.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_providers.dart';
import 'game_ui_state.dart';

/// Owns the turn cycle: the human moves, then the robot answers after a beat.
///
/// The pause lives here rather than in a use case so that the domain stays
/// free of UI timing.
class GameNotifier extends Notifier<GameUiState> {
  bool _disposed = false;
  int _generation = 0;

  @override
  GameUiState build() {
    _disposed = false;
    // A rebuild starts a new game too, so stale replies from the previous
    // one must be invalidated here as well as in startNewGame().
    _generation++;
    ref.onDispose(() => _disposed = true);
    return GameUiState(game: ref.read(startGameProvider)());
  }

  Future<void> playAt(int index) async {
    if (!state.canPlay || !state.game.board.isEmptyAt(index)) {
      return;
    }

    final generation = _generation;
    final afterHuman = ref.read(playHumanMoveProvider)(index);
    state = GameUiState(game: afterHuman);
    if (afterHuman.isOver) {
      return;
    }

    state = state.withRobotThinking(true);
    await Future<void>.delayed(ref.read(robotDelayProvider));
    // A new game started while we waited makes this reply stale: the
    // repository now holds a fresh game, and playing on it would stamp the
    // robot's move as X before the human has moved.
    if (_disposed || generation != _generation) {
      return;
    }
    state = GameUiState(game: ref.read(playRobotMoveProvider)());
  }

  void startNewGame() {
    _generation++;
    state = GameUiState(game: ref.read(startGameProvider)());
  }
}
```

- [ ] **Step 6: Write the providers**

Create `lib/presentation/providers/game_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_game_repository.dart';
import '../../data/services/random_robot_strategy.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/robot_strategy.dart';
import '../../domain/usecases/play_human_move.dart';
import '../../domain/usecases/play_robot_move.dart';
import '../../domain/usecases/start_game.dart';
import 'game_notifier.dart';
import 'game_ui_state.dart';

/// Composition root: the only place where interfaces meet implementations.
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => InMemoryGameRepository(),
);

final robotStrategyProvider = Provider<RobotStrategy>(
  (ref) => RandomRobotStrategy(),
);

final startGameProvider = Provider<StartGame>(
  (ref) => StartGame(ref.watch(gameRepositoryProvider)),
);

final playHumanMoveProvider = Provider<PlayHumanMove>(
  (ref) => PlayHumanMove(ref.watch(gameRepositoryProvider)),
);

final playRobotMoveProvider = Provider<PlayRobotMove>(
  (ref) => PlayRobotMove(
    ref.watch(gameRepositoryProvider),
    ref.watch(robotStrategyProvider),
  ),
);

/// How long the robot appears to think before answering.
/// Tests override this with [Duration.zero].
final robotDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 500),
);

// Auto-dispose so that leaving the game page really does end the game:
// re-entering the route rebuilds the notifier and deals a fresh board,
// rather than depending on a caller to reset it first.
final gameNotifierProvider = NotifierProvider<GameNotifier, GameUiState>(
  GameNotifier.new,
  isAutoDispose: true,
);
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `flutter test test/presentation/providers/game_notifier_test.dart`
Expected: PASS

If `flutter pub add` installed a Riverpod major version whose API differs from
the code above — a changed `Notifier` / `NotifierProvider` pair, or a
`ProviderContainer` constructor that is deprecated in favour of
`ProviderContainer.test()` — follow the package's own migration notes for those
constructs only. If the analyzer reports a deprecation, adopt the replacement
the deprecation names rather than leaving a warning behind. The layering, the
provider names and the test expectations stay exactly as written.

- [ ] **Step 8: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

---

### Task 6: Board widgets

**Files:**
- Create: `lib/presentation/widgets/cell_view.dart`
- Create: `lib/presentation/widgets/board_view.dart`
- Create: `lib/presentation/widgets/game_status_banner.dart`
- Test: `test/presentation/widgets/board_view_test.dart`
- Test: `test/presentation/widgets/game_status_banner_test.dart`

**Interfaces:**
- Consumes: `Board`, `Mark`, `Game`, `GameStatus` and `GameUiState` from Tasks 1, 2 and 5.
- Produces:
  - `class CellView extends StatelessWidget` — `const CellView({Key? key, required int index, required Mark? mark, required bool highlighted, required VoidCallback? onTap})`. Each cell carries `key: ValueKey('cell-$index')` and a semantics label `cell-$index`.
  - `class BoardView extends StatelessWidget` — `const BoardView({Key? key, required Board board, required List<int>? winningLine, required void Function(int index)? onCellTap})`.
  - `class GameStatusBanner extends StatelessWidget` — `const GameStatusBanner({Key? key, required GameUiState state})` with `String get message` and the static copy constants `yourTurn`, `thinking`, `youWin`, `robotWins`, `draw`.

- [ ] **Step 1: Write the failing tests**

Create `test/presentation/widgets/board_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/board.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/mark.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/board_view.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/cell_view.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Finder cell(int index) => find.byKey(ValueKey('cell-$index'));

void main() {
  group('BoardView', () {
    testWidgets('renders nine cells', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty(),
            winningLine: null,
            onCellTap: (_) {},
          ),
        ),
      );

      for (var index = 0; index < 9; index++) {
        expect(cell(index), findsOneWidget);
      }
    });

    testWidgets('renders the marks that are on the board', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty().placeMark(0, Mark.x).placeMark(8, Mark.o),
            winningLine: null,
            onCellTap: (_) {},
          ),
        ),
      );

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    });

    testWidgets('reports the index of a tapped empty cell', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty(),
            winningLine: null,
            onCellTap: tapped.add,
          ),
        ),
      );

      await tester.tap(cell(4));

      expect(tapped, [4]);
    });

    testWidgets('ignores a tap on a cell that is taken', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty().placeMark(4, Mark.x),
            winningLine: null,
            onCellTap: tapped.add,
          ),
        ),
      );

      await tester.tap(cell(4), warnIfMissed: false);

      expect(tapped, isEmpty);
    });

    testWidgets('marks only the winning cells as highlighted', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty()
                .placeMark(0, Mark.x)
                .placeMark(1, Mark.x)
                .placeMark(2, Mark.x),
            winningLine: const [0, 1, 2],
            onCellTap: null,
          ),
        ),
      );

      for (var index = 0; index < 9; index++) {
        expect(
          tester.widget<CellView>(cell(index)).highlighted,
          index <= 2,
          reason: 'cell $index',
        );
      }
    });

    testWidgets('paints a highlighted cell differently from a plain one', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty(),
            winningLine: const [0, 1, 2],
            onCellTap: null,
          ),
        ),
      );

      Color? colorOf(int index) => tester
          .widget<Material>(
            find.descendant(of: cell(index), matching: find.byType(Material)),
          )
          .color;

      expect(colorOf(0), isNot(colorOf(4)));
    });

    testWidgets('ignores every tap when onCellTap is null', (tester) async {
      await tester.pumpWidget(
        wrap(
          BoardView(
            board: Board.empty(),
            winningLine: null,
            onCellTap: null,
          ),
        ),
      );

      await tester.tap(cell(0), warnIfMissed: false);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
```

Create `test/presentation/widgets/game_status_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/domain/entities/game.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_ui_state.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/game_status_banner.dart';

Game playAll(List<int> indices) {
  var game = Game.start();
  for (final index in indices) {
    game = game.playAt(index);
  }
  return game;
}

Future<void> pumpBanner(WidgetTester tester, GameUiState state) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameStatusBanner(state: state))),
    );

void main() {
  group('GameStatusBanner', () {
    testWidgets('prompts the human on their turn', (tester) async {
      await pumpBanner(tester, GameUiState(game: Game.start()));

      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
    });

    testWidgets('announces the robot thinking', (tester) async {
      await pumpBanner(
        tester,
        GameUiState(game: Game.start().playAt(0), robotThinking: true),
      );

      expect(find.text(GameStatusBanner.thinking), findsOneWidget);
    });

    testWidgets('announces a human win', (tester) async {
      await pumpBanner(tester, GameUiState(game: playAll([0, 3, 1, 4, 2])));

      expect(find.text(GameStatusBanner.youWin), findsOneWidget);
    });

    testWidgets('announces a robot win', (tester) async {
      await pumpBanner(tester, GameUiState(game: playAll([0, 3, 1, 4, 8, 5])));

      expect(find.text(GameStatusBanner.robotWins), findsOneWidget);
    });

    testWidgets('announces a draw', (tester) async {
      await pumpBanner(
        tester,
        GameUiState(game: playAll([0, 1, 2, 4, 3, 5, 7, 6, 8])),
      );

      expect(find.text(GameStatusBanner.draw), findsOneWidget);
    });
  });

  // The tests above compare rendered text to the banner's own constants, so
  // they cannot catch a constant whose value drifted. This pins the wording
  // the spec fixes. The \u2026 escape states the ellipsis unambiguously
  // instead of relying on a glyph that is easy to mistype as three dots.
  group('copy', () {
    test('matches the wording the spec fixes', () {
      expect(GameStatusBanner.yourTurn, 'Your turn');
      expect(GameStatusBanner.thinking, 'Robot is thinking\u2026');
      expect(GameStatusBanner.youWin, 'You win!');
      expect(GameStatusBanner.robotWins, 'Robot wins!');
      expect(GameStatusBanner.draw, 'Draw');
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/presentation/widgets`
Expected: FAIL — the widget files do not exist.

- [ ] **Step 3: Write `CellView`**

Create `lib/presentation/widgets/cell_view.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/mark.dart';

/// One square of the board.
///
/// [onTap] is null when the square cannot be played, which also greys it out.
class CellView extends StatelessWidget {
  const CellView({
    super.key,
    required this.index,
    required this.mark,
    required this.highlighted,
    required this.onTap,
  });

  final int index;
  final Mark? mark;

  /// True when this cell is part of the winning line.
  final bool highlighted;

  final VoidCallback? onTap;

  String get _symbol => switch (mark) {
    Mark.x => 'X',
    Mark.o => 'O',
    null => '',
  };

  /// Describes the cell to a screen reader. Cells are numbered 1-9 for the
  /// listener; the `ValueKey` carries the 0-based index for the tests.
  String get _semanticsLabel {
    final occupant = switch (mark) {
      Mark.x => 'your X',
      Mark.o => "the robot's O",
      null => 'empty',
    };
    return highlighted
        ? 'Cell ${index + 1}, $occupant, part of the winning line'
        : 'Cell ${index + 1}, $occupant';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: _semanticsLabel,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: highlighted ? colors.primaryContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              _symbol,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: mark == Mark.x ? colors.primary : colors.tertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write `BoardView`**

Create `lib/presentation/widgets/board_view.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/board.dart';
import 'cell_view.dart';

/// The 3x3 grid.
///
/// Passing a null [onCellTap] disables the whole board, which is how the UI
/// stops the human moving out of turn or after the game ends.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.winningLine,
    required this.onCellTap,
  });

  final Board board;
  final List<int>? winningLine;
  final void Function(int index)? onCellTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: Board.size,
        itemBuilder: (context, index) {
          final mark = board.cellAt(index);
          final playable = onCellTap != null && mark == null;
          return CellView(
            key: ValueKey('cell-$index'),
            index: index,
            mark: mark,
            highlighted: winningLine?.contains(index) ?? false,
            onTap: playable ? () => onCellTap!(index) : null,
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Write `GameStatusBanner`**

Create `lib/presentation/widgets/game_status_banner.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/entities/game_status.dart';
import '../../domain/entities/mark.dart';
import '../providers/game_ui_state.dart';

/// The single line of text above the board.
class GameStatusBanner extends StatelessWidget {
  const GameStatusBanner({super.key, required this.state});

  static const String yourTurn = 'Your turn';
  static const String thinking = 'Robot is thinking…';
  static const String youWin = 'You win!';
  static const String robotWins = 'Robot wins!';
  static const String draw = 'Draw';

  final GameUiState state;

  String get message => switch (state.game.status) {
    Win(winner: final winner) => winner == Mark.x ? youWin : robotWins,
    Draw() => draw,
    InProgress() => state.robotThinking ? thinking : yourTurn,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/presentation/widgets`
Expected: PASS

- [ ] **Step 7: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

---

### Task 7: The game page

**Files:**
- Create: `lib/presentation/pages/game_page.dart`
- Test: `test/presentation/pages/game_page_test.dart`

**Interfaces:**
- Consumes: `gameNotifierProvider`, `robotStrategyProvider`, `robotDelayProvider` (Task 5); `BoardView`, `GameStatusBanner` (Task 6); `StubRobotStrategy` (Task 3).
- Produces: `class GamePage extends ConsumerWidget` — `const GamePage({Key? key})`. The `@RoutePage()` annotation is added in Task 8, once `auto_route` is installed.

- [ ] **Step 1: Write the failing test**

Create `test/presentation/pages/game_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/pages/game_page.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_providers.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/board_view.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/game_status_banner.dart';

import '../../helpers/fakes.dart';

Finder cell(int index) => find.byKey(ValueKey('cell-$index'));

Future<void> pumpGamePage(WidgetTester tester, List<int> robotMoves) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [
          robotStrategyProvider.overrideWithValue(
            StubRobotStrategy(robotMoves),
          ),
          robotDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: const MaterialApp(home: GamePage()),
      ),
    );

void main() {
  group('GamePage', () {
    testWidgets('opens on an empty board prompting the human', (tester) async {
      await pumpGamePage(tester, []);

      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
      expect(find.text('X'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text('Play again'), findsNothing);
    });

    testWidgets('marks the tapped cell and lets the robot reply', (
      tester,
    ) async {
      await pumpGamePage(tester, [4]);

      await tester.tap(cell(0));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
    });

    testWidgets('announces a win and offers a rematch', (tester) async {
      await pumpGamePage(tester, [3, 4]);

      for (final index in [0, 1, 2]) {
        await tester.tap(cell(index));
        await tester.pumpAndSettle();
      }

      expect(find.text(GameStatusBanner.youWin), findsOneWidget);
      expect(find.text('Play again'), findsOneWidget);
    });

    testWidgets('Play again clears the board', (tester) async {
      await pumpGamePage(tester, [3, 4]);
      for (final index in [0, 1, 2]) {
        await tester.tap(cell(index));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
      expect(find.text('Play again'), findsNothing);
    });

    testWidgets('disables the board while the robot is thinking', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            robotStrategyProvider.overrideWithValue(StubRobotStrategy([4])),
            robotDelayProvider.overrideWithValue(
              const Duration(milliseconds: 100),
            ),
          ],
          child: const MaterialApp(home: GamePage()),
        ),
      );

      await tester.tap(cell(0));
      await tester.pump(); // one frame: the human move landed, robot pending

      expect(find.text(GameStatusBanner.thinking), findsOneWidget);
      expect(tester.widget<BoardView>(find.byType(BoardView)).onCellTap, isNull);

      // A tap now must be ignored entirely.
      await tester.tap(cell(1), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    });

    testWidgets('scrolls instead of overflowing on a short viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpGamePage(tester, []);

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('a tap on a taken cell changes nothing', (tester) async {
      await pumpGamePage(tester, [4]);
      await tester.tap(cell(0));
      await tester.pumpAndSettle();

      await tester.tap(cell(0), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('O'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/presentation/pages/game_page_test.dart`
Expected: FAIL — `game_page.dart` does not exist.

- [ ] **Step 3: Write the page**

Create `lib/presentation/pages/game_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_status.dart';
import '../providers/game_providers.dart';
import '../widgets/board_view.dart';
import '../widgets/game_status_banner.dart';

class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameNotifierProvider);
    final notifier = ref.read(gameNotifierProvider.notifier);
    final status = state.game.status;

    return Scaffold(
      appBar: AppBar(title: const Text('Tic Tac Toe')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Centres the board when there is room, and scrolls rather than
            // overflowing when there is not. A plain Column overflows by a
            // few pixels on short viewports, including the default test
            // surface.
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameStatusBanner(state: state),
                          const SizedBox(height: 24),
                          BoardView(
                            board: state.game.board,
                            winningLine: status is Win ? status.line : null,
                            onCellTap: state.canPlay ? notifier.playAt : null,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 48,
                            child: state.game.isOver
                                ? FilledButton(
                                    onPressed: notifier.startNewGame,
                                    child: const Text('Play again'),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

The fixed-height `SizedBox` keeps the board from jumping when the rematch
button appears.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/presentation/pages/game_page_test.dart`
Expected: PASS

- [ ] **Step 5: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

---

### Task 8: Routing, the landing page, and app wiring

**Files:**
- Modify: `pubspec.yaml` (add `auto_route`, `build_runner`, `auto_route_generator`)
- Create: `lib/presentation/pages/home_page.dart`
- Modify: `lib/presentation/pages/game_page.dart` (add the `@RoutePage()` annotation)
- Create: `lib/presentation/routing/app_router.dart`
- Generated: `lib/presentation/routing/app_router.gr.dart` (produced by `build_runner`; keep it in the tree)
- Modify: `lib/main.dart` (replace the Flutter counter scaffold)
- Delete: `test/widget_test.dart` (the generated counter test)
- Test: `test/presentation/pages/home_page_test.dart`
- Test: `test/main_test.dart`

**Interfaces:**
- Consumes: `GamePage` (Task 7), `gameNotifierProvider`, `robotStrategyProvider`, `robotDelayProvider` (Task 5).
- Produces:
  - `class HomePage extends StatelessWidget` annotated `@RoutePage()` — `const HomePage({Key? key})`. It holds no state and needs no Riverpod: the game provider is auto-dispose, so entering `GameRoute` rebuilds the notifier and deals a fresh board without the page resetting anything.
  - `class AppRouter extends RootStackRouter` annotated `@AutoRouterConfig()`, with `HomeRoute` (initial) and `GameRoute` generated into `app_router.gr.dart`.
  - `class TicTacToeApp extends StatefulWidget` in `main.dart` — `const TicTacToeApp({Key? key})`.

- [ ] **Step 1: Add the routing dependencies**

```bash
flutter pub add auto_route
flutter pub add dev:build_runner dev:auto_route_generator
```

- [ ] **Step 2: Write the failing tests**

Create `test/presentation/pages/home_page_test.dart`:

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/pages/game_page.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/providers/game_providers.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/routing/app_router.dart';
import 'package:tic_tac_toe_v2_flutter/presentation/widgets/game_status_banner.dart';

import '../../helpers/fakes.dart';

Finder cell(int index) => find.byKey(ValueKey('cell-$index'));

Future<AppRouter> pumpApp(WidgetTester tester, List<int> robotMoves) async {
  final router = AppRouter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        robotStrategyProvider.overrideWithValue(
          StubRobotStrategy(robotMoves),
        ),
        robotDelayProvider.overrideWithValue(Duration.zero),
      ],
      child: MaterialApp.router(routerConfig: router.config()),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('HomePage', () {
    testWidgets('is the first screen', (tester) async {
      await pumpApp(tester, []);

      expect(find.text('Tic Tac Toe'), findsOneWidget);
      expect(find.text('Play a round against the robot.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Play'), findsOneWidget);
      expect(find.byType(GamePage), findsNothing);
    });

    testWidgets('Play opens the game on an empty board', (tester) async {
      await pumpApp(tester, []);

      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();

      expect(find.byType(GamePage), findsOneWidget);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
      expect(find.text('X'), findsNothing);
    });

    testWidgets('a second game starts fresh after going back', (tester) async {
      final router = await pumpApp(tester, [4]);

      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();
      await tester.tap(cell(0));
      await tester.pumpAndSettle();
      expect(find.text('X'), findsOneWidget);

      await router.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsNothing);
      expect(find.text('O'), findsNothing);
      expect(find.text(GameStatusBanner.yourTurn), findsOneWidget);
    });
  });
}
```

Create `test/main_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe_v2_flutter/main.dart';

void main() {
  testWidgets('the app boots on the landing page', (tester) async {
    await tester.pumpWidget(const TicTacToeAppRoot());
    await tester.pumpAndSettle();

    expect(find.text('Tic Tac Toe'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Delete the generated counter test**

The scaffold's `test/widget_test.dart` tests a counter app that no longer
exists once `main.dart` is rewritten.

```bash
rm test/widget_test.dart
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `flutter test test/presentation/pages/home_page_test.dart test/main_test.dart`
Expected: FAIL — `home_page.dart`, `app_router.dart` and `TicTacToeAppRoot` do not exist.

- [ ] **Step 5: Annotate `GamePage` for routing**

In `lib/presentation/pages/game_page.dart`, add the import and the annotation:

```dart
import 'package:auto_route/auto_route.dart';
```

```dart
@RoutePage()
class GamePage extends ConsumerWidget {
```

- [ ] **Step 6: Write the landing page**

Create `lib/presentation/pages/home_page.dart`:

```dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../routing/app_router.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tic Tac Toe', style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                'Play a round against the robot.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.router.push(const GameRoute()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Play'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Write the router**

Create `lib/presentation/routing/app_router.dart`:

```dart
import 'package:auto_route/auto_route.dart';

import '../pages/game_page.dart';
import '../pages/home_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
    AutoRoute(page: GameRoute.page),
  ];
}
```

- [ ] **Step 8: Generate the route classes**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/presentation/routing/app_router.gr.dart` is written, defining
`HomeRoute` and `GameRoute`.

If the installed `auto_route` major version expects a different shape here (for
example a `extension` instead of a `part`, or `RootStackRouter` renamed), follow
the generator's own error message to adjust `app_router.dart` only. Everything
else in this task — the page code, `main.dart`, and the tests — is unaffected.

- [ ] **Step 9: Rewrite `main.dart`**

Replace the entire contents of `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/routing/app_router.dart';

void main() {
  runApp(const TicTacToeAppRoot());
}

/// The app plus its provider scope, so widget tests can pump the real thing.
class TicTacToeAppRoot extends StatelessWidget {
  const TicTacToeAppRoot({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderScope(child: TicTacToeApp());
}

class TicTacToeApp extends StatefulWidget {
  const TicTacToeApp({super.key});

  @override
  State<TicTacToeApp> createState() => _TicTacToeAppState();
}

class _TicTacToeAppState extends State<TicTacToeApp> {
  final AppRouter _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tic Tac Toe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: _router.config(),
    );
  }
}
```

- [ ] **Step 10: Run the tests to verify they pass**

Run: `flutter test test/presentation/pages/home_page_test.dart test/main_test.dart`
Expected: PASS

- [ ] **Step 11: Verify the whole suite and the analyzer**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

- [ ] **Step 12: Check the app actually runs**

Run: `flutter run -d chrome` (or any device attached to this machine)
Expected: the landing page appears; **Play** opens the board; tapping a cell
draws an X and the robot answers with an O after a short pause; winning, losing
or drawing shows the matching message and a **Play again** button that clears
the board.

---

## Done when

- `flutter test` is green and `flutter analyze` reports no issues.
- The app launches on the landing page, **Play** starts a game, the robot
  replies to every human move, and **Play again** resets the board.
- No file under `lib/domain/` imports Flutter, Riverpod, auto_route, `lib/data/`
  or `lib/presentation/`.
- Version control is untouched: no repository was initialised and no commits
  were made.


---

## Amendment — Freezed conversion (after the plan was executed)

This plan was written and executed against hand-written `Equatable` models.
After it completed, the four models were converted to Freezed, so the model
code blocks in Tasks 1, 2 and 5 above describe the *pre-conversion* shape and
are kept as the historical record of how the app was built. The current design
is described in the spec's **Models** section.

What changed: `equatable` was replaced by `freezed_annotation` (runtime) and
`freezed` (dev); `Board`, `GameStatus`, `Game` and `GameUiState` became Freezed
classes with committed `.freezed.dart` part files; `GameStatus` became a union
whose case classes keep the names `InProgress`, `Win` and `Draw`, so no pattern
match changed; `GameUiState.withRobotThinking` was replaced by Freezed's
generated `copyWith`; and `Board` lost its `List.unmodifiable` constructor wrap,
which removed the test `'cannot be mutated through the cells it was built from'`.

Regenerate with `dart run build_runner build --delete-conflicting-outputs`.
