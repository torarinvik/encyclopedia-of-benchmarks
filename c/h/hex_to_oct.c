#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-2147483649)

static int hex_digit(int64_t code) {
    if (code >= '0' && code <= '9') return (int)(code - '0');
    if (code >= 'A' && code <= 'F') return (int)(code - 'A' + 10);
    if (code >= 'a' && code <= 'f') return (int)(code - 'a' + 10);
    return -1;
}

static int64_t signed_i32(uint32_t bits) {
    return bits <= INT32_MAX ? (int64_t)bits : (int64_t)bits - INT64_C(4294967296);
}

int64_t hex_to_oct(const int64_t *input, size_t length) {
    if (length > 8 || (length != 0 && input == NULL)) return INVALID_RESULT;
    uint32_t decimal_bits = 0;
    for (size_t index = 0; index < length; ++index) {
        const int digit = hex_digit(input[index]);
        if (digit < 0) return INVALID_RESULT;
        decimal_bits = decimal_bits * 16u + (uint32_t)digit;
    }
    int64_t decimal = signed_i32(decimal_bits);
    if (decimal <= 0) return 0;

    uint32_t octal_bits = 0;
    uint32_t place_value = 1;
    while (decimal > 0) {
        octal_bits += (uint32_t)(decimal % 8) * place_value;
        decimal /= 8;
        place_value *= 10u;
    }
    return signed_i32(octal_bits);
}
