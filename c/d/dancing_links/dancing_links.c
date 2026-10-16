#include <stddef.h>
#include <stdint.h>

static void search(unsigned columns, unsigned row_count, const uint64_t *rows,
                   unsigned covered, unsigned selected, uint8_t *solutions, size_t *count)
{
    unsigned full = (1u << columns) - 1u;
    if (covered == full) { solutions[(*count)++] = (uint8_t)selected; return; }
    unsigned best_column = columns + 1, best_count = row_count + 1;
    for (unsigned col = 0; col < columns; ++col) {
        unsigned bit = 1u << col;
        if (covered & bit) continue;
        unsigned candidates = 0;
        for (unsigned row = 0; row < row_count; ++row)
            if ((rows[row] & bit) && !(rows[row] & covered)) ++candidates;
        if (!candidates) return;
        if (candidates < best_count) { best_count = candidates; best_column = col; }
    }
    unsigned bit = 1u << best_column;
    for (unsigned row = 0; row < row_count; ++row)
        if ((rows[row] & bit) && !(rows[row] & covered))
            search(columns, row_count, rows, covered | (unsigned)rows[row], selected | (1u << row), solutions, count);
}

int64_t dancing_links(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (!input || length < 2 || length > 10) return -1;
    int64_t columns = input[0], row_count = input[1];
    if (columns < 1 || columns > 8 || row_count < 0 || row_count > 8 || length != (size_t)row_count + 2) return -1;
    uint64_t full = (1u << columns) - 1u, rows[8] = {0};
    for (int64_t i = 0; i < row_count; ++i) {
        if (input[i + 2] <= 0 || ((uint64_t)input[i + 2] & ~full)) return -1;
        rows[i] = (uint64_t)input[i + 2];
    }
    uint8_t solutions[256]; size_t count = 0;
    search((unsigned)columns, (unsigned)row_count, rows, 0, 0, solutions, &count);
    for (size_t i = 1; i < count; ++i) { uint8_t x = solutions[i]; size_t j = i; while (j && solutions[j-1] > x) { solutions[j] = solutions[j-1]; --j; } solutions[j] = x; }
    if (output_capacity < count || (count && !output)) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = solutions[i];
    return (int64_t)count;
}
