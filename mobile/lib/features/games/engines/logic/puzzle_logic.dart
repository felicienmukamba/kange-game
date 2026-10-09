import 'dart:math';

import '../../../../core/utils/seeded_random.dart';

/// A question with one correct answer among [options].
class GeneratedQuestion {
  const GeneratedQuestion(this.prompt, this.options, this.answer);

  final String prompt;
  final List<String> options;
  final int answer;
}

/// Arithmetic problems whose difficulty grows with [level] (0-based).
GeneratedQuestion mathQuestion(SeededRandom rnd, int level, {bool hardcore = false}) {
  final tier = min(level ~/ 3 + (hardcore ? 2 : 0), 5);
  late int a, b, result;
  late String symbol;
  switch (rnd.nextInt(tier >= 2 ? 4 : 3)) {
    case 0:
      a = 2 + rnd.nextInt(10 + tier * 15);
      b = 2 + rnd.nextInt(10 + tier * 15);
      result = a + b;
      symbol = '+';
    case 1:
      a = 5 + rnd.nextInt(15 + tier * 15);
      b = 1 + rnd.nextInt(a);
      result = a - b;
      symbol = '−';
    case 2:
      a = 2 + rnd.nextInt(5 + tier * 2);
      b = 2 + rnd.nextInt(5 + tier * 2);
      result = a * b;
      symbol = '×';
    default:
      b = 2 + rnd.nextInt(8 + tier);
      result = 2 + rnd.nextInt(8 + tier);
      a = b * result;
      symbol = '÷';
  }
  return _withDistractors(rnd, '$a $symbol $b = ?', result);
}

GeneratedQuestion _withDistractors(SeededRandom rnd, String prompt, int result) {
  final options = <int>{result};
  var spread = max(3, result.abs() ~/ 5);
  while (options.length < 4) {
    final delta = rnd.nextInt(spread * 2 + 1) - spread;
    if (delta != 0) options.add(result + delta);
    spread++;
  }
  final list = options.toList();
  rnd.shuffle(list);
  return GeneratedQuestion(prompt, list.map((e) => '$e').toList(), list.indexOf(result));
}

/// "Quel nombre suit ?" — arithmetic, geometric, squares, Fibonacci-like and alternating series.
GeneratedQuestion sequenceQuestion(SeededRandom rnd, int level) {
  final kind = rnd.nextInt(min(5, 2 + level ~/ 2));
  final terms = <int>[];
  switch (kind) {
    case 0: // arithmetic
      final start = rnd.nextInt(20);
      final step = 2 + rnd.nextInt(9);
      for (var i = 0; i < 6; i++) {
        terms.add(start + step * i);
      }
    case 1: // geometric
      final start = 1 + rnd.nextInt(4);
      final ratio = 2 + rnd.nextInt(2);
      for (var i = 0; i < 6; i++) {
        terms.add(start * pow(ratio, i).toInt());
      }
    case 2: // squares / cubes shifted
      final offset = rnd.nextInt(5);
      final cube = rnd.nextBool() && level > 4;
      for (var i = 1; i <= 6; i++) {
        terms.add(pow(i + offset, cube ? 3 : 2).toInt());
      }
    case 3: // Fibonacci-like
      var a = 1 + rnd.nextInt(4), b = 1 + rnd.nextInt(5);
      terms.addAll([a, b]);
      for (var i = 0; i < 4; i++) {
        final c = a + b;
        terms.add(c);
        a = b;
        b = c;
      }
    default: // alternating +x, -y
      final x = 3 + rnd.nextInt(6), y = 1 + rnd.nextInt(x - 1);
      var v = rnd.nextInt(10);
      for (var i = 0; i < 6; i++) {
        terms.add(v);
        v += i.isEven ? x : -y;
      }
  }
  final shown = terms.take(5).join(', ');
  return _withDistractors(rnd, '$shown, … ?', terms.last);
}

// ------------------------------------------------------------------ sudoku

/// Sudoku with [size] 4, 6 or 9. [solution] is complete; [puzzle] has 0 for blanks.
class Sudoku {
  Sudoku._(this.size, this.boxRows, this.boxCols, this.solution, this.puzzle);

  final int size;
  final int boxRows;
  final int boxCols;
  final List<int> solution;
  final List<int> puzzle;

  static Sudoku generate(SeededRandom rnd, {int size = 4}) {
    final (br, bc) = switch (size) { 9 => (3, 3), 6 => (2, 3), _ => (2, 2) };
    final n = br * bc;
    // Base pattern then shuffle digits, rows within bands and columns within stacks.
    int pattern(int r, int c) => (bc * (r % br) + r ~/ br + c) % n;
    final digits = List.generate(n, (i) => i + 1);
    rnd.shuffle(digits);
    List<int> shuffledGroups(int groups, int per) {
      final order = List.generate(groups, (i) => i);
      rnd.shuffle(order);
      return [
        for (final g in order)
          ...(() {
            final inner = List.generate(per, (i) => g * per + i);
            rnd.shuffle(inner);
            return inner;
          })(),
      ];
    }

    final rows = shuffledGroups(n ~/ br, br);
    final cols = shuffledGroups(n ~/ bc, bc);
    final solution = [for (final r in rows) for (final c in cols) digits[pattern(r, c)]];

    final puzzle = List.of(solution);
    final cells = List.generate(n * n, (i) => i);
    rnd.shuffle(cells);
    final blanks = switch (n) { 9 => 46, 6 => 18, _ => 8 };
    for (final cell in cells.take(blanks)) {
      puzzle[cell] = 0;
    }
    return Sudoku._(n, br, bc, solution, puzzle);
  }

  /// Whether [value] at [index] conflicts with filled cells in [grid].
  bool conflicts(List<int> grid, int index, int value) {
    if (value == 0) return false;
    final r = index ~/ size, c = index % size;
    for (var i = 0; i < size; i++) {
      if (i != c && grid[r * size + i] == value) return true;
      if (i != r && grid[i * size + c] == value) return true;
    }
    final r0 = r - r % boxRows, c0 = c - c % boxCols;
    for (var rr = r0; rr < r0 + boxRows; rr++) {
      for (var cc = c0; cc < c0 + boxCols; cc++) {
        if ((rr != r || cc != c) && grid[rr * size + cc] == value) return true;
      }
    }
    return false;
  }

  /// Solved when full and conflict-free (any valid solution counts).
  bool isSolved(List<int> grid) {
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] == 0 || conflicts(grid, i, grid[i])) return false;
    }
    return true;
  }
}

// ------------------------------------------------------------------ sliding puzzle

/// 15-puzzle board; `0` is the hole. Shuffled by random legal moves so it is always solvable.
class SlidingBoard {
  SlidingBoard(this.size, this.tiles);

  factory SlidingBoard.shuffled(SeededRandom rnd, int size) {
    final board = SlidingBoard(size, [...List.generate(size * size - 1, (i) => i + 1), 0]);
    var previous = -1;
    for (var i = 0; i < size * size * 25; i++) {
      final moves = board.movable().where((m) => m != previous).toList();
      final pick = moves[rnd.nextInt(moves.length)];
      previous = board.hole;
      board.move(pick);
    }
    if (board.isSolved) board.move(board.movable().first);
    return board;
  }

  final int size;
  final List<int> tiles;

  int get hole => tiles.indexOf(0);

  bool get isSolved {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  List<int> movable() {
    final h = hole, r = h ~/ size, c = h % size;
    return [
      if (r > 0) h - size,
      if (r < size - 1) h + size,
      if (c > 0) h - 1,
      if (c < size - 1) h + 1,
    ];
  }

  /// Moves the tile at [index] into the hole if adjacent.
  bool move(int index) {
    if (!movable().contains(index)) return false;
    final h = hole;
    tiles[h] = tiles[index];
    tiles[index] = 0;
    return true;
  }
}
