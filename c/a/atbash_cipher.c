/* Apply the case-preserving Atbash mapping to a 7-bit ASCII byte sequence. */
#include <stddef.h>
#include <stdint.h>

int64_t atbash_cipher(const int64_t *input, size_t length, uint8_t *output,
                      size_t output_capacity)
{
    if (length > 66) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (output_capacity < length) return -2;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        int64_t mapped = value;
        if (value >= 65 && value <= 90) mapped = 155 - value;
        else if (value >= 97 && value <= 122) mapped = 219 - value;
        output[index] = (uint8_t)mapped;
    }
    return (int64_t)length;
}
