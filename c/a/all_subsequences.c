/* Emit subsequences in skip-before-include depth-first order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 8
#define BYTES_PER_VALUE 4

static void store_u32_le(uint8_t *output, size_t position, uint32_t value)
{
    for (size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = (uint8_t)(value >> (byte * 8));
}

static void store_i32_le(uint8_t *output, size_t position, int32_t value)
{
    store_u32_le(output, position, (uint32_t)value);
}

static void generate(const int32_t *values, size_t n, size_t index,
                     int32_t *current, size_t current_length,
                     uint8_t *output, size_t *output_cursor,
                     size_t *result_count)
{
    if (index == n) {
        store_u32_le(output, *output_cursor, (uint32_t)current_length);
        *output_cursor += BYTES_PER_VALUE;
        for (size_t item = 0; item < current_length; ++item) {
            store_i32_le(output, *output_cursor, current[item]);
            *output_cursor += BYTES_PER_VALUE;
        }
        ++*result_count;
        return;
    }
    generate(values, n, index + 1, current, current_length,
             output, output_cursor, result_count);
    current[current_length] = values[index];
    generate(values, n, index + 1, current, current_length + 1,
             output, output_cursor, result_count);
}

int64_t all_subsequences(const int64_t *input, size_t length,
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
    size_t result_count = 1;
    for (size_t index = 0; index < n; ++index) result_count *= 2;
    const size_t value_count = n == 0 ? 0 : n * (result_count / 2);
    const size_t required = (result_count + value_count) * BYTES_PER_VALUE;
    if (output_capacity < required || output == NULL) return -2;
    int32_t current[MAX_LENGTH];
    size_t output_cursor = 0;
    size_t emitted = 0;
    generate(values, n, 0, current, 0, output, &output_cursor, &emitted);
    return (int64_t)emitted;
}
