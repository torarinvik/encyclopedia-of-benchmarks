/* Rotate an array right by repeating a one-place shift. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 1024
#define MAX_INPUT_LENGTH (MAX_ARRAY_LENGTH + 1)
#define MAX_ROTATIONS 1024

int64_t rotate_array(const int64_t *input, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rotations_value = input[0];
    if (rotations_value < 0 || rotations_value > MAX_ROTATIONS) return -1;
    const size_t count = length - 1;
    int32_t values[MAX_ARRAY_LENGTH];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = (int32_t)value;
    }
    const size_t output_bytes = count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    for (int64_t step = 0; step < rotations_value && count > 1; ++step) {
        const int32_t last = values[count - 1];
        for (size_t index = count - 1; index > 0; --index) values[index] = values[index - 1];
        values[0] = last;
    }
    for (size_t index = 0; index < count; ++index) {
        const uint32_t bits = (uint32_t)values[index];
        for (size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)count;
}
