/* Emit the reflected n-bit Gray-code sequence as little-endian u32 values. */
#include <stddef.h>
#include <stdint.h>

int64_t gray_code(const int64_t *input, size_t input_length,
                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length != 1 || input[0] < 0 || input[0] > 13) return -1;
    const unsigned bits = (unsigned)input[0];
    const size_t count = bits == 0 ? 0 : ((size_t)1 << bits);
    const size_t required = count * 4;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < count; ++index) {
        const uint32_t value = (uint32_t)(index ^ (index >> 1));
        for (unsigned byte = 0; byte < 4; ++byte)
            output[4 * index + byte] = (uint8_t)(value >> (8 * byte));
    }
    return (int64_t)count;
}
