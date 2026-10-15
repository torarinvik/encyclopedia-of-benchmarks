/* Emit permutations in depth-first input-index order; equal values keep multiplicity. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 6
#define BYTES_PER_VALUE 4

static void store_i32_le(uint8_t *output, size_t position, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

static void generate(const int32_t *values, size_t n, size_t depth,
                     int32_t *current, uint8_t *used,
                     uint8_t *output, size_t *result_count)
{
    if (depth == n) {
        const size_t row_start = *result_count * n * BYTES_PER_VALUE;
        for (size_t index = 0; index < n; ++index)
            store_i32_le(output, row_start + index * BYTES_PER_VALUE, current[index]);
        ++*result_count;
        return;
    }
    for (size_t index = 0; index < n; ++index) {
        if (used[index]) continue;
        current[depth] = values[index];
        used[index] = 1;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[index] = 0;
    }
}

int64_t all_permutations(const int64_t *input, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_LENGTH + 1) return -1;
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
    const size_t required = permutation_count * n * BYTES_PER_VALUE;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    int32_t current[MAX_LENGTH];
    uint8_t used[MAX_LENGTH] = {0};
    size_t result_count = 0;
    generate(values, n, 0, current, used, output, &result_count);
    return (int64_t)result_count;
}
