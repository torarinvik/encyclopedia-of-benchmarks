/*
Fhourstones 2.0 copyright and distribution notice:
This software is copyright (c) 1996 by John Tromp, Lindenlaan 33,
1701 GT Heerhugowaard, Netherlands. E-mail: tromp@cwi.nl.
This notice must not be removed. This software must not be sold for profit.
You may redistribute if your distributees have the same rights and restrictions.

Fhourstones 3.1 copyright and distribution notice:
This software is copyright (c) 1996-2005 by John Tromp, Insulindeweg 908,
1095 DX Amsterdam, Netherlands. E-mail: tromp@cwi.nl.
This notice must not be removed. This software must not be sold for profit.
You may redistribute if your distributees have the same rights and restrictions.
*/
const WIDTH: usize = 7;
const HEIGHT: usize = 6;
const BOARD_CELLS: usize = 42;
const MIN_MOVES: i64 = 36;
const MAX_MOVES: i64 = 41;
const MOVE_ORDER = [_]usize{ 3, 2, 4, 1, 5, 0, 6 };
const DIR_X = [_]i32{ 1, 0, 1, 1 };
const DIR_Y = [_]i32{ 0, 1, 1, -1 };

fn winsAt(board: *const [BOARD_CELLS]i8, column: i32, row: i32, side: i8) bool {
    const width_i: i32 = @intCast(WIDTH);
    const height_i: i32 = @intCast(HEIGHT);
    for (0..4) |direction| {
        var count: i32 = 1;
        for ([_]i32{ -1, 1 }) |sign| {
            for (1..4) |step_usize| {
                const step: i32 = @intCast(step_usize);
                const x = column + sign * step * DIR_X[direction];
                const y = row + sign * step * DIR_Y[direction];
                if (x < 0 or x >= width_i or y < 0 or y >= height_i) break;
                if (board.*[@intCast(y * width_i + x)] != side) break;
                count += 1;
            }
        }
        if (count >= 4) return true;
    }
    return false;
}

fn solveEndgame(board: *[BOARD_CELLS]i8, heights: *[WIDTH]usize, side: i8,
    remaining: usize, alpha_in: i32, beta: i32) i32 {
    if (remaining == 0) return 0;
    var alpha = alpha_in;
    var best: i32 = -3;
    for (MOVE_ORDER) |column| {
        const row = heights.*[column];
        if (row == HEIGHT) continue;
        board.*[row * WIDTH + column] = side;
        heights.*[column] = row + 1;
        const value = if (winsAt(board, @intCast(column), @intCast(row), side)) 2 else
            -solveEndgame(board, heights, if (side == 1) 2 else 1, remaining - 1, -beta, -alpha);
        heights.*[column] = row;
        board.*[row * WIDTH + column] = 0;
        if (value > best) best = value;
        if (value > alpha) alpha = value;
        if (alpha >= beta) break;
    }
    return best;
}

pub export fn fhourstones_exact(input: [*c]const i64, input_length: usize) i64 {
    if (input == null or input_length < 2 or input_length > 42) return -1;
    const count_value = input[0];
    if (count_value < MIN_MOVES or count_value > MAX_MOVES) return -1;
    const count: usize = @intCast(count_value);
    if (input_length != count + 1) return -1;

    var board = [_]i8{0} ** BOARD_CELLS;
    var heights = [_]usize{0} ** WIDTH;
    for (0..count) |turn| {
        const column_value = input[turn + 1];
        if (column_value < 0 or column_value >= @as(i64, @intCast(WIDTH))) return -1;
        const column: usize = @intCast(column_value);
        const row = heights[column];
        if (row >= HEIGHT) return -1;
        const side: i8 = if (turn % 2 == 0) 1 else 2;
        board[row * WIDTH + column] = side;
        heights[column] = row + 1;
        if (winsAt(&board, @intCast(column), @intCast(row), side)) return -1;
    }
    const side: i8 = if (count % 2 == 0) 1 else 2;
    return @intCast(solveEndgame(&board, &heights, side, BOARD_CELLS - count, -3, 3));
}
