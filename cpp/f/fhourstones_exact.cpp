/*
Fhourstones 2.0 copyright and distribution notice:
This software is copyright (c) 1996 by
     John Tromp
     Lindenlaan 33
     1701 GT Heerhugowaard
     Netherlands
E-mail: tromp@cwi.nl
This notice must not be removed.
This software must not be sold for profit.
You may redistribute if your distributees have the
same rights and restrictions.

Fhourstones 3.1 copyright and distribution notice:
This software is copyright (c) 1996-2005 by
     John Tromp
     Insulindeweg 908
     1095 DX Amsterdam
     Netherlands
E-mail: tromp@cwi.nl
This notice must not be removed.
This software must not be sold for profit.
You may redistribute if your distributees have the
same rights and restrictions.
*/
#include <stddef.h>
#include <stdint.h>

namespace {
enum { WIDTH = 7, HEIGHT = 6, BOARD_CELLS = 42, MIN_MOVES = 36,
       MAX_MOVES = 41, MAX_INPUT_LENGTH = 42 };
const int MOVE_ORDER[WIDTH] = {3, 2, 4, 1, 5, 0, 6};
const int DIR_X[4] = {1, 0, 1, 1};
const int DIR_Y[4] = {0, 1, 1, -1};

int wins_at(const int8_t board[BOARD_CELLS], int column, int row, int player) {
    for (int direction = 0; direction < 4; ++direction) {
        int count = 1;
        for (int sign = -1; sign <= 1; sign += 2) {
            for (int step = 1; step < 4; ++step) {
                int x = column + sign * step * DIR_X[direction];
                int y = row + sign * step * DIR_Y[direction];
                if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT ||
                    board[y * WIDTH + x] != player) break;
                ++count;
            }
        }
        if (count >= 4) return 1;
    }
    return 0;
}

int solve_endgame(int8_t board[BOARD_CELLS], int height[WIDTH], int side,
                  int remaining, int alpha, int beta) {
    if (remaining == 0) return 0;
    int best = -3;
    for (int index = 0; index < WIDTH; ++index) {
        int column = MOVE_ORDER[index];
        int row = height[column];
        if (row == HEIGHT) continue;
        board[row * WIDTH + column] = static_cast<int8_t>(side);
        height[column] = row + 1;
        int value;
        if (wins_at(board, column, row, side)) value = 2;
        else value = -solve_endgame(board, height, side == 1 ? 2 : 1,
                                    remaining - 1, -beta, -alpha);
        height[column] = row;
        board[row * WIDTH + column] = 0;
        if (value > best) best = value;
        if (value > alpha) alpha = value;
        if (alpha >= beta) break;
    }
    return best;
}
} // namespace

extern "C" int64_t fhourstones_exact(const int64_t *input, size_t input_length) {
    if (input == nullptr || input_length < 2u || input_length > MAX_INPUT_LENGTH)
        return -1;
    int64_t count_value = input[0];
    if (count_value < MIN_MOVES || count_value > MAX_MOVES) return -1;
    int count = static_cast<int>(count_value);
    if (input_length != static_cast<size_t>(count) + 1u) return -1;

    int8_t board[BOARD_CELLS] = {};
    int height[WIDTH] = {};
    for (int turn = 0; turn < count; ++turn) {
        int64_t column_value = input[static_cast<size_t>(turn) + 1u];
        if (column_value < 0 || column_value >= WIDTH) return -1;
        int column = static_cast<int>(column_value);
        int row = height[column];
        if (row >= HEIGHT) return -1;
        int side = turn % 2 == 0 ? 1 : 2;
        board[row * WIDTH + column] = static_cast<int8_t>(side);
        height[column] = row + 1;
        if (wins_at(board, column, row, side)) return -1;
    }

    int remaining = BOARD_CELLS - count;
    int side_to_move = count % 2 == 0 ? 1 : 2;
    return solve_endgame(board, height, side_to_move, remaining, -3, 3);
}
