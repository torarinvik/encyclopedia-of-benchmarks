#include <stddef.h>
#include <stdint.h>

static int hex_digit(int64_t code) {
    if (code >= '0' && code <= '9') return (int)(code - '0');
    if (code >= 'A' && code <= 'F') return (int)(code - 'A' + 10);
    if (code >= 'a' && code <= 'f') return (int)(code - 'a' + 10);
    return -1;
}

int64_t hexa_decimal_to_binary(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity) {
    if (input == NULL || length == 0 || length > 65) return -1;
    size_t first_digit = 0;
    int negative = 0;
    if (input[0] == '-') { negative = 1; first_digit = 1; }
    else if (input[0] == '+') first_digit = 1;
    if (first_digit == length) return -1;
    uint64_t value = 0;
    const uint64_t limit = negative ? UINT64_C(2147483648) : (uint64_t)INT32_MAX;
    for (size_t index = first_digit; index < length; ++index) {
        const int digit = hex_digit(input[index]);
        if (digit < 0 || value > (limit - (uint64_t)digit) / 16) return -1;
        value = value * 16 + (uint64_t)digit;
    }
    uint32_t bits = negative ? 0u - (uint32_t)value : (uint32_t)value;
    size_t width = 0;
    for (uint32_t remaining = bits; remaining != 0; remaining >>= 1) ++width;
    if (negative && value != 0) width = 32;
    else if (width < 8) width = 8;
    uint8_t buffer[32];
    uint32_t remaining = bits;
    for (size_t position = width; position > 0;) {
        --position;
        buffer[position] = (uint8_t)('0' + remaining % 2);
        remaining /= 2;
    }
    if (width > output_capacity || output == NULL) return -2;
    for (size_t index = 0; index < width; ++index) output[index] = buffer[index];
    return (int64_t)width;
}
