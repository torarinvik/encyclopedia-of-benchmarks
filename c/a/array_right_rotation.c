/* Return a new array right-rotated by shift, or empty when shift >= length. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 1024
#define MAX_INPUT_LENGTH (MAX_ARRAY_LENGTH + 1)
#define MAX_SHIFT 1024

static void write_i32_le(uint8_t *output, size_t index, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[index * 4 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t array_right_rotation(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t shift_value = input[0];
    if (shift_value < 0 || shift_value > MAX_SHIFT) return -1;
    const size_t count = length - 1;
    int32_t values[MAX_ARRAY_LENGTH];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = (int32_t)value;
    }
    const size_t shift = (size_t)shift_value;
    if (shift >= count) return 0;
    const size_t output_bytes = count * 4;
    if (output_capacity < output_bytes || output == NULL) return -2;
    for (size_t index = 0; index < shift; ++index)
        write_i32_le(output, index, values[count - shift + index]);
    for (size_t index = shift; index < count; ++index)
        write_i32_le(output, index, values[index - shift]);
    return (int64_t)count;
}
