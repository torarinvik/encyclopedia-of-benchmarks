#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 4, MAX_COLS = 4, MAX_CELLS = 16, MAX_LENGTH = 19, MAX_TOPPLES = 1488 };

int64_t abelian_sandpile_stabilization(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_LENGTH) return -1;
    const int64_t rows_word = input[0];
    const int64_t cols_word = input[1];
    if (rows_word < 1 || rows_word > MAX_ROWS || cols_word < 1 || cols_word > MAX_COLS)
        return -1;
    const size_t rows = (size_t)rows_word;
    const size_t cols = (size_t)cols_word;
    const size_t cells = rows * cols;
    if (length != 2 + cells) return -1;

    int64_t board[MAX_CELLS] = {0};
    for (size_t site = 0; site < cells; ++site) {
        if (input[2 + site] < 0 || input[2 + site] > 31) return -1;
        board[site] = input[2 + site];
    }

    size_t queue[MAX_CELLS] = {0};
    int queued[MAX_CELLS] = {0};
    size_t head = 0, tail = 0, queued_count = 0;
#define ENQUEUE(site_) do { \
    size_t q_site = (site_); \
    if (board[q_site] >= 4 && !queued[q_site]) { \
        queue[tail] = q_site; tail = (tail + 1) % cells; ++queued_count; queued[q_site] = 1; \
    } \
} while (0)
    for (size_t site = 0; site < cells; ++site) ENQUEUE(site);

    size_t topples = 0;
    while (queued_count > 0) {
        const size_t site = queue[head];
        head = (head + 1) % cells;
        --queued_count;
        queued[site] = 0;
        if (board[site] < 4) continue;

        const size_t row = site / cols;
        const size_t col = site % cols;
        board[site] -= 4;
        if (++topples > MAX_TOPPLES) return -1;
        if (row > 0) { const size_t next = site - cols; ++board[next]; ENQUEUE(next); }
        if (col + 1 < cols) { const size_t next = site + 1; ++board[next]; ENQUEUE(next); }
        if (row + 1 < rows) { const size_t next = site + cols; ++board[next]; ENQUEUE(next); }
        if (col > 0) { const size_t next = site - 1; ++board[next]; ENQUEUE(next); }
        ENQUEUE(site);
    }
#undef ENQUEUE

    int64_t result = 0;
    int64_t place = 1;
    for (size_t site = 0; site < cells; ++site) {
        result += board[site] * place;
        place *= 4;
    }
    return result;
}
