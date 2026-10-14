/* Encode bytes as uppercase Base16 or decode uppercase Base16 bytes. */
#include <stddef.h>
#include <stdint.h>
static const uint8_t alphabet[] = "0123456789ABCDEF";
static int64_t nibble(int64_t byte) {
    if (byte >= '0' && byte <= '9') return byte - '0';
    if (byte >= 'A' && byte <= 'F') return byte - 'A' + 10;
    return -1;
}
int64_t base16(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > 65) return -1;
    const int64_t mode = input[0];
    if (mode == 0) {
        const size_t count = length - 1, output_length = count * 2;
        for (size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
        if (output_capacity < output_length) return -2;
        for (size_t i = 0; i < count; ++i) {
            const int64_t byte = input[i + 1];
            output[2 * i] = alphabet[byte / 16]; output[2 * i + 1] = alphabet[byte % 16];
        }
        return (int64_t)output_length;
    }
    if (mode == 1) {
        const size_t encoded_length = length - 1;
        if (encoded_length % 2 != 0) return -1;
        for (size_t i = 1; i < length; ++i) if (nibble(input[i]) < 0) return -1;
        const size_t output_length = encoded_length / 2;
        if (output_capacity < output_length) return -2;
        for (size_t i = 0; i < output_length; ++i)
            output[i] = (uint8_t)(nibble(input[1 + 2 * i]) * 16 + nibble(input[2 + 2 * i]));
        return (int64_t)output_length;
    }
    return -1;
}
