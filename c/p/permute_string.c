#include <stddef.h>
#include <stdint.h>

#define MAX_N 7
#define MAX_INPUT_LENGTH 9
#define MAX_OUTPUT_BYTES 35280

static size_t factorial(size_t value)
{
    size_t result = 1;
    for (size_t factor = 2; factor <= value; ++factor) result *= factor;
    return result;
}

static size_t unique_permutation_count(const uint8_t *values, size_t length)
{
    if (length == 0) return 0;
    size_t frequencies[128] = {0};
    for (size_t index = 0; index < length; ++index) ++frequencies[values[index]];
    size_t count = factorial(length);
    for (size_t value = 0; value < 128; ++value) count /= factorial(frequencies[value]);
    return count;
}

static int next_permutation(uint8_t *values, size_t length)
{
    if (length < 2) return 0;
    size_t pivot = length - 1;
    while (pivot > 0 && values[pivot - 1] >= values[pivot]) --pivot;
    if (pivot == 0) return 0;
    size_t successor = length - 1;
    while (values[successor] <= values[pivot - 1]) --successor;
    const uint8_t temporary = values[pivot - 1];
    values[pivot - 1] = values[successor];
    values[successor] = temporary;
    for (size_t left = pivot, right = length - 1; left < right; ++left, --right) {
        const uint8_t value = values[left];
        values[left] = values[right];
        values[right] = value;
    }
    return 1;
}

int64_t permute_string(const int64_t *input, size_t input_length,
                       uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t character_count = (size_t)input[0];
    if (input_length != character_count + 1) return -1;

    uint8_t values[MAX_N] = {0};
    for (size_t index = 0; index < character_count; ++index) {
        const int64_t value = input[index + 1];
        if (value < 0 || value > 127) return -1;
        values[index] = (uint8_t)value;
    }
    for (size_t index = 1; index < character_count; ++index) {
        const uint8_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }

    const size_t permutation_count = unique_permutation_count(values, character_count);
    const size_t output_bytes = permutation_count * character_count;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t row = 0; row < permutation_count; ++row) {
        for (size_t column = 0; column < character_count; ++column)
            output[row * character_count + column] = values[column];
        if (row + 1 < permutation_count) (void)next_permutation(values, character_count);
    }
    return (int64_t)output_bytes;
}
