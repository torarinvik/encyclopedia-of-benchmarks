/* XOR each input byte with a repeating key byte sequence. */
#include <stddef.h>
#include <stdint.h>

int64_t xor_cipher(const int64_t *input, size_t length, uint8_t *output,
                   size_t output_capacity)
{
    if (length < 3 || length > 66 || input[0] < 0 || input[0] > 63 ||
        input[1] < 1 || input[1] > 63) return -1;
    const size_t text_length = (size_t)input[0];
    const size_t key_length = (size_t)input[1];
    if (length != 2 + text_length + key_length) return -1;
    for (size_t index = 0; index < text_length + key_length; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 255) return -1;
    if (output_capacity < text_length) return -2;
    for (size_t index = 0; index < text_length; ++index)
        output[index] = (uint8_t)(input[2 + index] ^ input[2 + text_length + index % key_length]);
    return (int64_t)text_length;
}
