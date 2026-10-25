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
module fhourstones_exact;

const int WIDTH = 7, HEIGHT = 6, BOARD_CELLS = 42;
const int MIN_MOVES = 36, MAX_MOVES = 41, MAX_INPUT_LENGTH = 42;
const int MOVE_ORDER[7] = {3, 2, 4, 1, 5, 0, 6};
const int DIR_X[4] = {1, 0, 1, 1};
const int DIR_Y[4] = {0, 1, 1, -1};

fn bool wins_at(char* board, int column, int row, int side) {
    for (int direction = 0; direction < 4; direction++) {
        int count = 1;
        for (int sign = -1; sign <= 1; sign += 2) {
            for (int step = 1; step < 4; step++) {
                int x = column + sign * step * DIR_X[direction];
                int y = row + sign * step * DIR_Y[direction];
                if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT ||
                    board[y * WIDTH + x] != side) break;
                count++;
            }
        }
        if (count >= 4) return true;
    }
    return false;
}

fn int solve_endgame(char* board, int* height, int side, int remaining,
                     int alpha, int beta) {
    if (remaining == 0) return 0;
    int best = -3;
    for (int index = 0; index < WIDTH; index++) {
        int column = MOVE_ORDER[index];
        int row = height[column];
        if (row == HEIGHT) continue;
        board[row * WIDTH + column] = (char)side;
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

fn long fhourstones_exact(long* input, usz input_length) @export("fhourstones_exact") {
    if (input == null || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < MIN_MOVES || count_value > MAX_MOVES) return -1;
    int count = (int)count_value;
    if (input_length != (usz)count + 1) return -1;

    char board[BOARD_CELLS] = {0};
    int height[WIDTH] = {0};
    for (int turn = 0; turn < count; turn++) {
        long column_value = input[(usz)turn + 1];
        if (column_value < 0 || column_value >= WIDTH) return -1;
        int column = (int)column_value;
        int row = height[column];
        if (row >= HEIGHT) return -1;
        int side = turn % 2 == 0 ? 1 : 2;
        board[row * WIDTH + column] = (char)side;
        height[column] = row + 1;
        if (wins_at(board, column, row, side)) return -1;
    }
    int side = count % 2 == 0 ? 1 : 2;
    return solve_endgame(board, height, side, BOARD_CELLS - count, -3, 3);
}
