#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_BYTES 5000
#define MAX_INPUT_VALUES (MAX_INPUT_BYTES + 1)
#define CHUNK_WIDTH 50
#define MAX_DIGITS (CHUNK_WIDTH + 2)
#define MAX_OUTPUT_BYTES 10

int64_t problem13_chunks(const int64_t *values, size_t length,
                         uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 1 || values[0] > MAX_INPUT_BYTES ||
        (size_t)values[0] != length - 1) return -1;

    const size_t byte_length = (size_t)values[0];
    for (size_t index = 0; index < byte_length; ++index) {
        if (values[index + 1] < '0' || values[index + 1] > '9') return -1;
    }

    const size_t width = byte_length < CHUNK_WIDTH ? byte_length : CHUNK_WIDTH;
    uint8_t reversed[MAX_DIGITS];
    size_t reversed_length = 0;
    int64_t carry = 0;
    for (size_t remaining = width; remaining > 0; --remaining) {
        const size_t position = remaining - 1;
        int64_t column = carry;
        for (size_t start = 0; start < byte_length; start += CHUNK_WIDTH) {
            const size_t chunk_length = byte_length - start < CHUNK_WIDTH
                ? byte_length - start : CHUNK_WIDTH;
            if (position < chunk_length) {
                column += values[1 + start + position] - '0';
            }
        }
        reversed[reversed_length++] = (uint8_t)(column % 10);
        carry = column / 10;
    }
    while (carry > 0) {
        reversed[reversed_length++] = (uint8_t)(carry % 10);
        carry /= 10;
    }

    const size_t output_length = reversed_length < MAX_OUTPUT_BYTES
        ? reversed_length : MAX_OUTPUT_BYTES;
    if (output == NULL || capacity < output_length) return -2;
    for (size_t index = 0; index < output_length; ++index) {
        output[index] = (uint8_t)('0' + reversed[reversed_length - 1 - index]);
    }
    return (int64_t)output_length;
}
