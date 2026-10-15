#include <stddef.h>
#include <stdint.h>

int64_t decimal_to_hex(int64_t value, uint8_t *output, size_t capacity) {
    if (value < 0 || value > INT64_C(9007199254740991)) return -1;
    size_t width = 1;
    for (int64_t n = value; n >= 16; n /= 16) ++width;
    if (output == NULL || capacity < width) return -2;
    size_t position = width;
    do {
        int64_t digit = value % 16;
        output[--position] = (uint8_t)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        value /= 16;
    } while (position > 0);
    return (int64_t)width;
}
