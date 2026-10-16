#include <stddef.h>
#include <stdint.h>

static const int DR[8] = {2, 1, -1, -2, -2, -1, 1, 2};
static const int DC[8] = {1, 2, 2, 1, -1, -2, -2, -1};

static int solve(int board[8][8], int row, int col, int step) {
    if (step == 64) return 1;
    for (int move = 0; move < 8; ++move) {
        int next_row = row + DR[move], next_col = col + DC[move];
        if (next_row >= 0 && next_row < 8 && next_col >= 0 && next_col < 8 && board[next_row][next_col] == -1) {
            board[next_row][next_col] = step;
            if (solve(board, next_row, next_col, step + 1)) return 1;
            board[next_row][next_col] = -1;
        }
    }
    return 0;
}
static void put_i64(uint8_t *output, size_t index, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[index * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t knight_tour_open_dfs(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (length != 0) return -1;
    if (output == NULL || capacity < 64 * 8) return -2;
    int board[8][8];
    for (int row = 0; row < 8; ++row) for (int col = 0; col < 8; ++col) board[row][col] = -1;
    board[0][0] = 0;
    if (!solve(board, 0, 0, 1)) return -1;
    int64_t path[64];
    for (int row = 0; row < 8; ++row) for (int col = 0; col < 8; ++col) path[board[row][col]] = row * 8 + col;
    for (size_t i = 0; i < 64; ++i) put_i64(output, i, path[i]);
    return 512;
}
