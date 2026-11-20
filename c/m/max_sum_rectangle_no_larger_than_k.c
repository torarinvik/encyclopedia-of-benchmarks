#include <stddef.h>
#include <stdint.h>

enum {
    MAX_ROWS = 8,
    MAX_COLUMNS = 8,
    MAX_PARSEABLE_LENGTH = 68,
    NO_FEASIBLE = -1025,
    INVALID_INPUT = -1026
};

static int64_t best_subarray_at_most(const int64_t *values, size_t count, int64_t limit)
{
    int64_t prefixes[MAX_COLUMNS + 1];
    size_t prefix_count = 1;
    int64_t running = 0;
    int64_t best = NO_FEASIBLE;
    prefixes[0] = 0;
    for (size_t i = 0; i < count; ++i) {
        running += values[i];
        const int64_t threshold = running - limit;
        size_t low = 0, high = prefix_count;
        while (low < high) {
            const size_t middle = low + (high - low) / 2;
            if (prefixes[middle] < threshold) low = middle + 1;
            else high = middle;
        }
        if (low < prefix_count) {
            const int64_t candidate = running - prefixes[low];
            if (best == NO_FEASIBLE || candidate > best) best = candidate;
        }
        size_t insert = prefix_count;
        while (insert > 0 && prefixes[insert - 1] > running) {
            prefixes[insert] = prefixes[insert - 1];
            --insert;
        }
        prefixes[insert] = running;
        ++prefix_count;
    }
    return best;
}

int64_t max_sum_rectangle_no_larger_than_k(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_LENGTH) return INVALID_INPUT;
    const int64_t rows_value = input[0], columns_value = input[1], limit = input[2];
    if (rows_value < 1 || rows_value > MAX_ROWS
        || columns_value < 1 || columns_value > MAX_COLUMNS
        || limit < -1024 || limit > 1024) return INVALID_INPUT;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    if (length != 3 + rows * columns) return INVALID_INPUT;
    int64_t matrix[MAX_ROWS][MAX_COLUMNS] = {{0}};
    for (size_t row = 0; row < rows; ++row) {
        for (size_t column = 0; column < columns; ++column) {
            const int64_t value = input[3 + row * columns + column];
            if (value < -16 || value > 16) return INVALID_INPUT;
            matrix[row][column] = value;
        }
    }
    const size_t short_dimension = rows < columns ? rows : columns;
    const size_t long_dimension = rows < columns ? columns : rows;
    int64_t best = NO_FEASIBLE;
    for (size_t first = 0; first < short_dimension; ++first) {
        int64_t compressed[MAX_COLUMNS] = {0};
        for (size_t last = first; last < short_dimension; ++last) {
            for (size_t offset = 0; offset < long_dimension; ++offset) {
                compressed[offset] += rows <= columns
                    ? matrix[last][offset] : matrix[offset][last];
            }
            const int64_t candidate = best_subarray_at_most(compressed, long_dimension, limit);
            if (candidate != NO_FEASIBLE && (best == NO_FEASIBLE || candidate > best)) {
                best = candidate;
                if (best == limit) return best;
            }
        }
    }
    return best;
}
