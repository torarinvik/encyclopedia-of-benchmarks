/* Emit Java-style swap-recursion permutations, retaining duplicate rows. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 6
#define MAX_PARSEABLE_LENGTH 8

static void store_i32_le(uint8_t *output, size_t position, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

static void generate(int32_t *values, size_t n, size_t index,
                     uint8_t *output, size_t *result_count)
{
    if (index == n) {
        const size_t row_start = *result_count * n * 4;
        for (size_t column = 0; column < n; ++column)
            store_i32_le(output, row_start + column * 4, values[column]);
        ++*result_count;
        return;
    }
    for (size_t position = index; position < n; ++position) {
        const int32_t saved = values[index];
        values[index] = values[position];
        values[position] = saved;
        generate(values, n, index + 1, output, result_count);
        const int32_t restore = values[index];
        values[index] = values[position];
        values[position] = restore;
    }
}

int64_t permutation_array(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_LENGTH || length != (size_t)n_value + 1) return -1;
    const size_t n = (size_t)n_value;
    int32_t values[MAX_LENGTH];
    for (size_t index = 0; index < n; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = (int32_t)value;
    }
    size_t permutation_count = 1;
    for (size_t factor = 2; factor <= n; ++factor) permutation_count *= factor;
    const size_t required = permutation_count * n * 4;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    size_t result_count = 0;
    generate(values, n, 0, output, &result_count);
    return (int64_t)result_count;
}
