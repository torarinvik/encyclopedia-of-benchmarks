/* Return the decimal integer formed by the binary digits of a bounded hex value. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

static int64_t hex_digit(int64_t byte)
{
    if (byte >= 48 && byte <= 57) return byte - 48;
    if (byte >= 65 && byte <= 70) return byte - 65 + 10;
    if (byte >= 97 && byte <= 102) return byte - 97 + 10;
    return -1;
}

int64_t hex_to_bin(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 5) return INVALID_RESULT;
    size_t start = 0;
    int64_t sign = 1;
    if (input[0] == 45) {
        sign = -1;
        start = 1;
    }
    if (length - start < 1 || length - start > 4) return INVALID_RESULT;

    int64_t value = 0;
    for (size_t index = start; index < length; ++index) {
        const int64_t digit = hex_digit(input[index]);
        if (digit < 0) return INVALID_RESULT;
        value = value * 16 + digit;
    }
    if (value == 0) return INVALID_RESULT;

    int64_t decimal_binary_digits = 0;
    int64_t place = 1;
    while (value > 0) {
        decimal_binary_digits += (value % 2) * place;
        value /= 2;
        if (value > 0) place *= 10;
    }
    return sign * decimal_binary_digits;
}
