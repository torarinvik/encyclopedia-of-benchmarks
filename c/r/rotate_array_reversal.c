/* Rotate by reversing the whole array, then each side of the rotation. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 1024
#define MAX_INPUT_LENGTH (MAX_ARRAY_LENGTH + 1)

static void reverse_range(int32_t *values, size_t start, size_t end)
{
    while (start < end) {
        --end;
        if (start >= end) break;
        const int32_t temporary = values[start];
        values[start] = values[end];
        values[end] = temporary;
        ++start;
    }
}

int64_t rotate_array_reversal(const int64_t *input, size_t length,
                              uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t steps = input[0];
    if (steps < INT32_MIN || steps > INT32_MAX) return -1;
    const size_t count = length - 1;
    int32_t values[MAX_ARRAY_LENGTH];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = (int32_t)value;
    }
    const size_t output_bytes = count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t shift = 0;
    if (count != 0) {
        int64_t remainder = steps % (int64_t)count;
        if (remainder < 0) remainder += (int64_t)count;
        shift = (size_t)remainder;
    }
    reverse_range(values, 0, count);
    reverse_range(values, 0, shift);
    reverse_range(values, shift, count);
    for (size_t index = 0; index < count; ++index) {
        const uint32_t bits = (uint32_t)values[index];
        for (size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)count;
}
