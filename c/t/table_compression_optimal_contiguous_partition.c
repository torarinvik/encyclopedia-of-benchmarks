#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 8, MAX_COLUMNS = 8, MAX_INPUT = 66, OUTPUT_BYTES = 24 };

static int interval_cost(const int64_t *table, int rows, int columns, int start, int end)
{
    int runs = 0;
    int have_previous = 0;
    int64_t previous = 0;
    for (int row = 0; row < rows; ++row) {
        for (int column = start; column < end; ++column) {
            const int64_t value = table[row * columns + column];
            if (!have_previous || value != previous) ++runs;
            previous = value;
            have_previous = 1;
        }
    }
    return 2 * runs;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8;
    }
}

int64_t table_compression_optimal_contiguous_partition(const int64_t *values, size_t length,
                                                        uint8_t *output, size_t capacity)
{
    if (!values || length < 3 || length > MAX_INPUT || values[0] < 1 || values[0] > MAX_ROWS ||
        values[1] < 1 || values[1] > MAX_COLUMNS) return -1;
    const int rows = (int)values[0], columns = (int)values[1];
    if (length != (size_t)(2 + rows * columns)) return -1;
    for (int i = 0; i < rows * columns; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 15) return -1;

    int cost[MAX_COLUMNS + 1] = {0};
    int previous[MAX_COLUMNS + 1] = {0};
    for (int end = 1; end <= columns; ++end) {
        cost[end] = 0x3fffffff;
        for (int start = 0; start < end; ++start) {
            const int candidate = cost[start] + interval_cost(values + 2, rows, columns, start, end);
            if (candidate < cost[end]) {
                cost[end] = candidate;
                previous[end] = start;
            }
        }
    }

    int groups = 0;
    uint64_t cuts = 0;
    int end = columns;
    while (end > 0) {
        const int start = previous[end];
        if (start > 0) cuts |= UINT64_C(1) << (start - 1);
        ++groups;
        end = start;
    }
    uint8_t staged[OUTPUT_BYTES] = {0};
    put_i64(staged, 0, cost[columns]);
    put_i64(staged, 8, groups);
    put_i64(staged, 16, (int64_t)cuts);
    if (!output || capacity < OUTPUT_BYTES) return -2;
    for (size_t i = 0; i < OUTPUT_BYTES; ++i) output[i] = staged[i];
    return OUTPUT_BYTES;
}
