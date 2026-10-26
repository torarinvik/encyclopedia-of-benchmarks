/* GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
   Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
   Upstream countlib/count are under GNU GPL version 1; this derivative is licensed under GNU GPL version 1. */
#include <stddef.h>
#include <stdint.h>

int64_t prolangs_c_gnugo_liberty_count(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 726) return -1;
    int64_t row = input[0], col = input[1], color = input[2], count = input[3];
    if (row < 0 || row >= 19 || col < 0 || col >= 19 ||
        (color != 1 && color != 2) || count < 0 || count > 361 ||
        length != 4 + 2 * (size_t)count) return -1;
    uint8_t board[361] = {0}, seen[361] = {0}, liberty[361] = {0};
    for (int64_t k = 0; k < count; ++k) {
        int64_t index = input[4 + 2 * (size_t)k], stone = input[5 + 2 * (size_t)k];
        if (index < 0 || index >= 361 || (stone != 1 && stone != 2) || board[index]) return -1;
        board[index] = (uint8_t)stone;
    }
    int start = (int)(row * 19 + col);
    if (board[start] != color) return -1;
    int stack[361], top = 0, total = 0;
    stack[top++] = start; seen[start] = 1;
    while (top) {
        int at = stack[--top], r = at / 19, c = at % 19;
        int neighbors[4], n = 0;
        if (r > 0) neighbors[n++] = at - 19;
        if (r < 18) neighbors[n++] = at + 19;
        if (c > 0) neighbors[n++] = at - 1;
        if (c < 18) neighbors[n++] = at + 1;
        for (int j = 0; j < n; ++j) {
            int next = neighbors[j];
            if (board[next] == 0) { if (!liberty[next]) { liberty[next] = 1; ++total; } }
            else if (board[next] == color && !seen[next]) { seen[next] = 1; stack[top++] = next; }
        }
    }
    return total;
}
