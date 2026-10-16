#include <stddef.h>
#include <stdint.h>

#define MAX_SIZE 16
static void fill(int *board, int width, int row, int col, int mr, int mc, int *tile) {
    if (width == 1) return;
    int half = width / 2, t = (*tile)++;
    int qr[4] = {row, row, row + half, row + half};
    int qc[4] = {col, col + half, col, col + half};
    int cr[4] = {row + half - 1, row + half - 1, row + half, row + half};
    int cc[4] = {col + half - 1, col + half, col + half - 1, col + half};
    int missing = (mr < row + half) ? ((mc < col + half) ? 0 : 1) : ((mc < col + half) ? 2 : 3);
    for (int q = 0; q < 4; ++q) {
        int nr = mr, nc = mc;
        if (q != missing) { board[cr[q] * MAX_SIZE + cc[q]] = t; nr = cr[q]; nc = cc[q]; }
        fill(board, half, qr[q], qc[q], nr, nc, tile);
    }
}
int64_t tiling_problem(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n != 3 || v[0] < 1 || v[0] > MAX_SIZE || (v[0] & (v[0] - 1)) || v[1] < 0 || v[1] >= v[0] || v[2] < 0 || v[2] >= v[0]) return -1;
    int size = (int)v[0], board[MAX_SIZE * MAX_SIZE] = {0}, tile = 1;
    fill(board, size, 0, 0, (int)v[1], (int)v[2], &tile);
    size_t bytes = (size_t)size * size * 4;
    if (!out || cap < bytes) return -2;
    for (int i = 0; i < size * size; ++i) { uint32_t x = (uint32_t)board[(i / size) * MAX_SIZE + i % size]; for (int b = 0; b < 4; ++b) out[i * 4 + b] = (uint8_t)(x >> (8 * b)); }
    return (int64_t)bytes;
}
