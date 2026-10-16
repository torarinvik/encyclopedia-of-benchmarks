#include <stddef.h>
#include <stdint.h>

#define RGB_CHANNEL_COUNT 3
#define RGB_HEX_OUTPUT_LENGTH 7

static uint8_t hex_digit(int64_t value) {
    return (uint8_t)(value < 10 ? '0' + value : 'a' + value - 10);
}

int64_t rgbto_hex(const int64_t *input, size_t length,
                  uint8_t *output, size_t capacity) {
    if (length != RGB_CHANNEL_COUNT || input == NULL) return -1;
    for (size_t i = 0; i < RGB_CHANNEL_COUNT; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    if (capacity < RGB_HEX_OUTPUT_LENGTH || output == NULL) return -2;
    output[0] = '#';
    for (size_t i = 0; i < RGB_CHANNEL_COUNT; ++i) {
        output[1 + 2 * i] = hex_digit(input[i] >> 4);
        output[2 + 2 * i] = hex_digit(input[i] & 15);
    }
    return RGB_HEX_OUTPUT_LENGTH;
}
