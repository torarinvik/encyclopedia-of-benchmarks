#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_i32(uint8_t *out, size_t at, int32_t value) {
    uint32_t bits = (uint32_t)value;
    for (unsigned b = 0; b < 4; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t prolangs_c_numeric_token(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 24) return -1;
    char text[25];
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < 32 || input[i] > 127) return -1;
        text[i] = (char)input[i];
    }
    text[length] = '\0';
    size_t i = 0;
    uint32_t integer = 0;
    int had_integer = 0;
    if (text[i] >= '0' && text[i] <= '9') {
        had_integer = 1;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            unsigned digit = (unsigned)(text[i++] - '0');
            if (integer > (2147483647u - digit) / 10u) return -1;
            integer = integer * 10u + digit;
        }
        if (i == length) {
            if (capacity < 12 || output == NULL) return -2;
            put_i32(output, 0, 256); put_i32(output, 4, (int32_t)integer); put_i32(output, 8, 0);
            return 12;
        }
    }
    uint32_t fraction_digits = 0;
    unsigned fractional_count = 0;
    unsigned leading_fraction_zeros = 0;
    int has_dot = 0;
    if (i < length && text[i] == '.') {
        has_dot = 1; ++i;
        while (i < length && text[i] == '0') { ++leading_fraction_zeros; ++i; }
        if (leading_fraction_zeros > 6) return -1;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            if (fractional_count == 6) return -1;
            fraction_digits = fraction_digits * 10u + (uint32_t)(text[i++] - '0');
            ++fractional_count;
        }
        if (leading_fraction_zeros + fractional_count > 6) return -1;
    }
    float value = 0.0f;
    if (fractional_count != 0) {
        value = (float)fraction_digits;
        while (value >= 1.0f) value /= 10.0f;
        while (leading_fraction_zeros != 0) { value /= 10.0f; --leading_fraction_zeros; }
    }
    value += (float)integer;
    int has_exponent = 0;
    if (i < length && (text[i] == 'e' || text[i] == 'E')) {
        has_exponent = 1; ++i;
        int sign = 1;
        if (i < length && (text[i] == '+' || text[i] == '-')) {
            if (text[i++] == '-') sign = -1;
        }
        if (i == length || text[i] < '0' || text[i] > '9') return -1;
        int exponent = 0;
        while (i < length && text[i] >= '0' && text[i] <= '9') {
            exponent = exponent * 10 + (text[i++] - '0');
            if (exponent > 6) return -1;
        }
        exponent *= sign;
        while (exponent > 0) { value *= 10.0f; --exponent; }
        while (exponent < 0) { value /= 10.0f; ++exponent; }
    }
    if (i != length || (!has_dot && !has_exponent) || (!had_integer && !has_dot)) return -1;
    if (capacity < 12 || output == NULL) return -2;
    int32_t bits;
    memcpy(&bits, &value, sizeof(bits));
    put_i32(output, 0, 2001); put_i32(output, 4, (int32_t)integer); put_i32(output, 8, bits);
    return 12;
}
