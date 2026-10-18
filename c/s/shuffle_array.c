/* Replay reverse Fisher-Yates or the Ruby half-interleave variant. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_PARSEABLE_INPUT_LENGTH 67
#define MAX_OUTPUT_BYTES 520
#define I32_MIN INT64_C(-2147483648)
#define I32_MAX INT64_C(2147483647)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t shuffle_array(const int64_t *input, size_t input_length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t variant = input[0];
    const int64_t n_value = input[1];
    if ((variant != 0 && variant != 1) || n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    const size_t value_count = variant == 0 ? n : 2 * n;
    const size_t draw_count = variant == 0 && n > 0 ? n - 1 : 0;
    if (input_length != 2 + value_count + draw_count) return -1;

    int64_t result_values[2 * MAX_N] = {0};
    size_t result_count = value_count;
    for (size_t index = 0; index < value_count; ++index) {
        const int64_t value = input[2 + index];
        if (value < I32_MIN || value > I32_MAX) return -1;
        result_values[index] = value;
    }

    if (variant == 0) {
        for (size_t draw_index = 0; draw_index < draw_count; ++draw_index) {
            const size_t current_index = n - 1 - draw_index;
            const int64_t chosen_value = input[2 + n + draw_index];
            if (chosen_value < 0 || chosen_value > (int64_t)current_index) return -1;
            const size_t chosen_index = (size_t)chosen_value;
            const int64_t temporary = result_values[current_index];
            result_values[current_index] = result_values[chosen_index];
            result_values[chosen_index] = temporary;
        }
    } else {
        for (size_t index = 0; index < n; ++index) {
            result_values[2 * index] = input[2 + index];
            result_values[2 * index + 1] = input[2 + n + index];
        }
    }

    const size_t output_bytes = 8 * (result_count + 1);
    if (output_bytes > MAX_OUTPUT_BYTES || output == NULL || output_capacity < output_bytes) return -2;
    store_i64_le(output, 0, (int64_t)result_count);
    for (size_t index = 0; index < result_count; ++index)
        store_i64_le(output, 8 * (index + 1), result_values[index]);
    return (int64_t)output_bytes;
}
