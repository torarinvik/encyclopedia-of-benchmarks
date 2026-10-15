/* Encode ASCII letters as their one-based alphabet positions. */
#include <stddef.h>
#include <stdint.h>

int64_t a1z26_cipher(const int64_t *input, size_t length, uint8_t *output,
                     size_t output_capacity)
{
    if (length > 66) return -1;
    for (size_t index = 0; index < length; ++index)
        if (!((input[index] >= 65 && input[index] <= 90) ||
              (input[index] >= 97 && input[index] <= 122))) return -1;
    if (output_capacity < length) return -2;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        output[index] = (uint8_t)(value >= 97 ? value - 96 : value - 64);
    }
    return (int64_t)length;
}
