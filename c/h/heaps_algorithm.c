#include <stddef.h>
#include <stdint.h>

enum { MAX_VALUES = 6, BYTES_PER_VALUE = 8 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void emit_row(const int64_t *values, size_t n, uint8_t *output, size_t *rows)
{
    const size_t row_offset = *rows * n * BYTES_PER_VALUE;
    for (size_t index = 0; index < n; ++index)
        store_i64_le(output, row_offset + index * BYTES_PER_VALUE, values[index]);
    ++*rows;
}

static void generate(int64_t *values, size_t n, size_t k,
                     uint8_t *output, size_t *rows)
{
    if (k == 1) {
        emit_row(values, n, output, rows);
        return;
    }
    generate(values, n, k - 1, output, rows);
    for (size_t index = 0; index < k - 1; ++index) {
        const size_t swap_index = k % 2 == 0 ? index : 0;
        const int64_t temporary = values[swap_index];
        values[swap_index] = values[k - 1];
        values[k - 1] = temporary;
        generate(values, n, k - 1, output, rows);
    }
}

int64_t heaps_algorithm(const int64_t *values, size_t length,
                        uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 1 || length > MAX_VALUES) return -1;
    size_t row_count = 1;
    for (size_t factor = 2; factor <= length; ++factor) row_count *= factor;
    const size_t required = row_count * length * BYTES_PER_VALUE;
    if (output == NULL || capacity < required) return -2;

    int64_t items[MAX_VALUES];
    for (size_t index = 0; index < length; ++index) items[index] = values[index];
    size_t rows = 0;
    generate(items, length, length, output, &rows);
    return (int64_t)rows;
}
