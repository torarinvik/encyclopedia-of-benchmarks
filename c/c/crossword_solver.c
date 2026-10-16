#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 64
#define MAX_WORDS 8
#define MAX_WORD_LENGTH 8

static int search_grid(int64_t *grid, size_t rows, size_t cols,
                       int64_t words[MAX_WORDS][MAX_WORD_LENGTH], size_t lengths[MAX_WORDS],
                       size_t *remaining, size_t remaining_count) {
    size_t start = 0;
    while (start < rows * cols && grid[start] != 0) ++start;
    if (start == rows * cols) return 1;
    const size_t row = start / cols, col = start % cols;
    size_t current[MAX_WORDS], current_count = remaining_count;
    for (size_t i = 0; i < remaining_count; ++i) current[i] = remaining[i];
    for (size_t wi = 0; wi < remaining_count; ++wi) {
        const size_t word_index = remaining[wi], word_length = lengths[word_index];
        for (int direction = 0; direction < 2; ++direction) {
            const int vertical = direction == 0;
            if ((vertical && row + word_length > rows) || (!vertical && col + word_length > cols)) continue;
            int valid = 1;
            for (size_t i = 0; i < word_length; ++i) {
                const size_t cell = vertical ? (row + i) * cols + col : row * cols + col + i;
                if (grid[cell] != 0) { valid = 0; break; }
            }
            if (!valid) continue;
            for (size_t i = 0; i < word_length; ++i) {
                const size_t cell = vertical ? (row + i) * cols + col : row * cols + col + i;
                grid[cell] = words[word_index][i];
            }
            size_t next[MAX_WORDS], next_count = 0;
            for (size_t i = 0; i < current_count; ++i) if (current[i] != word_index) next[next_count++] = current[i];
            size_t removed = 0;
            while (removed < current_count && current[removed] != word_index) ++removed;
            for (size_t i = removed + 1; i < current_count; ++i) current[i - 1] = current[i];
            --current_count;
            if (search_grid(grid, rows, cols, words, lengths, next, next_count)) return 1;
            for (size_t i = 0; i < word_length; ++i) {
                const size_t cell = vertical ? (row + i) * cols + col : row * cols + col + i;
                grid[cell] = 0;
            }
            current[current_count++] = word_index;
        }
    }
    return 0;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t crossword_solver(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3) return -1;
    const int64_t rows_value = input[0], cols_value = input[1], count_value = input[2];
    if (rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8 || count_value < 0 || count_value > 8) return -1;
    const size_t rows = (size_t)rows_value, cols = (size_t)cols_value, count = (size_t)count_value;
    if (length < 3 + rows * cols) return -1;
    int64_t grid[MAX_CELLS] = {0};
    for (size_t i = 0; i < rows * cols; ++i) {
        const int64_t value = input[3 + i];
        if (value != 0 && value != -1 && (value < 65 || value > 90)) return -1;
        grid[i] = value;
    }
    int64_t words[MAX_WORDS][MAX_WORD_LENGTH] = {{0}};
    size_t lengths[MAX_WORDS] = {0}, position = 3 + rows * cols;
    for (size_t w = 0; w < count; ++w) {
        if (position >= length || input[position] < 1 || input[position] > 8) return -1;
        lengths[w] = (size_t)input[position++];
        if (lengths[w] > length - position) return -1;
        for (size_t i = 0; i < lengths[w]; ++i) {
            if (input[position] < 65 || input[position] > 90) return -1;
            words[w][i] = input[position++];
        }
        for (size_t prior = 0; prior < w; ++prior) {
            int equal = lengths[prior] == lengths[w];
            for (size_t i = 0; equal && i < lengths[w]; ++i) if (words[prior][i] != words[w][i]) equal = 0;
            if (equal) return -1;
        }
    }
    if (position != length) return -1;
    size_t remaining[MAX_WORDS];
    for (size_t i = 0; i < count; ++i) remaining[i] = i;
    const int solved = search_grid(grid, rows, cols, words, lengths, remaining, count);
    const size_t used = 1 + rows * cols, required = used * 8;
    if (output == NULL || capacity < required) return -2;
    put_i64(output, 0, solved ? 1 : 0);
    for (size_t i = 0; i < rows * cols; ++i) put_i64(output, (i + 1) * 8, grid[i]);
    return (int64_t)required;
}
