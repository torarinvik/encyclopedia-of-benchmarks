#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 7 };

static void emit_row(const uint8_t *items, size_t n, uint8_t *output, size_t *rows)
{
    const size_t offset = *rows * n;
    for (size_t index = 0; index < n; ++index) output[offset + index] = items[index];
    ++*rows;
}

static void generate(uint8_t *items, size_t n, size_t size,
                     uint8_t *output, size_t *rows)
{
    if (size == 1) {
        emit_row(items, n, output, rows);
        return;
    }
    for (size_t index = 0; index < size; ++index) {
        generate(items, n, size - 1, output, rows);
        const size_t swap_index = size % 2 == 1 ? index : 0;
        const uint8_t temporary = items[swap_index];
        items[swap_index] = items[size - 1];
        items[size - 1] = temporary;
    }
}

int64_t heaps(const int64_t *values, size_t length,
              uint8_t *output, size_t capacity)
{
    if (values == NULL || length != 1 || values[0] < 0 || values[0] > MAX_N) return -1;
    const size_t n = (size_t)values[0];
    if (n == 0) return 0;
    size_t row_count = 1;
    for (size_t factor = 2; factor <= n; ++factor) row_count *= factor;
    const size_t required = row_count * n;
    if (output == NULL || capacity < required) return -2;
    uint8_t items[MAX_N];
    for (size_t index = 0; index < n; ++index) items[index] = (uint8_t)('1' + index);
    size_t rows = 0;
    generate(items, n, n, output, &rows);
    return (int64_t)rows;
}
