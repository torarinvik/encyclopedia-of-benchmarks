#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_CELLS 64
#define MAX_WORDS 8
#define MAX_WORD_LENGTH 8

static int search_grid(int64_t *grid, size_t rows, size_t cols,
                       const int64_t words[MAX_WORDS][MAX_WORD_LENGTH],
                       const size_t lengths[MAX_WORDS], const size_t order[MAX_WORDS],
                       size_t depth, size_t word_count) {
    if (depth == word_count) return 1;
    const size_t word_index = order[depth], word_length = lengths[word_index];
    for (size_t row = 0; row < rows; ++row) {
        for (size_t col = 0; col < cols; ++col) {
            for (int direction = 0; direction < 2; ++direction) {
                const int vertical = direction == 0;
                if ((vertical && row + word_length > rows) ||
                    (!vertical && col + word_length > cols)) continue;
                size_t cells[MAX_WORD_LENGTH];
                bool newly_filled[MAX_WORD_LENGTH];
                int valid = 1;
                for (size_t i = 0; i < word_length; ++i) {
                    cells[i] = vertical ? (row + i) * cols + col : row * cols + col + i;
                    if (grid[cells[i]] != 0 && grid[cells[i]] != words[word_index][i]) valid = 0;
                }
                if (!valid) continue;
                for (size_t i = 0; i < word_length; ++i) {
                    newly_filled[i] = grid[cells[i]] == 0;
                    grid[cells[i]] = words[word_index][i];
                }
                if (search_grid(grid, rows, cols, words, lengths, order, depth + 1, word_count)) return 1;
                for (size_t i = 0; i < word_length; ++i) if (newly_filled[i]) grid[cells[i]] = 0;
            }
        }
    }
    return 0;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t crossword_puzzle_solver(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3) return -1;
    const int64_t rows_value = input[0], cols_value = input[1], count_value = input[2];
    if (rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8 || count_value < 0 || count_value > 8) return -1;
    const size_t rows = (size_t)rows_value, cols = (size_t)cols_value, word_count = (size_t)count_value;
    if (length < 3 + rows * cols) return -1;
    int64_t grid[MAX_CELLS] = {0};
    for (size_t i = 0; i < rows * cols; ++i) {
        const int64_t value = input[3 + i];
        if (value != 0 && value != -1 && (value < 65 || value > 90)) return -1;
        grid[i] = value;
    }
    int64_t words[MAX_WORDS][MAX_WORD_LENGTH] = {{0}};
    size_t lengths[MAX_WORDS] = {0}, position = 3 + rows * cols;
    for (size_t w = 0; w < word_count; ++w) {
        if (position >= length || input[position] < 1 || input[position] > MAX_WORD_LENGTH) return -1;
        lengths[w] = (size_t)input[position++];
        if (lengths[w] > length - position) return -1;
        for (size_t i = 0; i < lengths[w]; ++i) {
            const int64_t letter = input[position++];
            if (letter < 65 || letter > 90) return -1;
            words[w][i] = letter;
        }
    }
    if (position != length) return -1;
    size_t order[MAX_WORDS];
    for (size_t i = 0; i < word_count; ++i) order[i] = i;
    for (size_t i = 1; i < word_count; ++i) {
        const size_t value = order[i];
        size_t j = i;
        while (j > 0 && lengths[order[j - 1]] < lengths[value]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = value;
    }
    const int solved = search_grid(grid, rows, cols, words, lengths, order, 0, word_count);
    const size_t required = (1 + rows * cols) * 8;
    if (output == NULL || capacity < required) return -2;
    put_i64(output, 0, solved ? 1 : 0);
    for (size_t i = 0; i < rows * cols; ++i) put_i64(output, (i + 1) * 8, grid[i]);
    return (int64_t)required;
}
