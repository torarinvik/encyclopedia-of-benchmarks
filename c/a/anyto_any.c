#include <stddef.h>
#include <stdint.h>

#define MAX_ENCODED_VALUE INT64_C(999999999)

int64_t anyto_any(const int64_t *input, size_t length)
{
    if (input == NULL || length != 3) return -1;
    int64_t encoded = input[0];
    int64_t source_base = input[1];
    int64_t destination_base = input[2];
    if (encoded < 0 || encoded > MAX_ENCODED_VALUE || source_base < 2 || source_base > 10 ||
        destination_base < 2 || destination_base > 10) return -1;

    int64_t decimal_value = 0;
    int64_t source_multiplier = 1;
    while (encoded > 0) {
        const int64_t digit = encoded % 10;
        if (digit >= source_base) return -1;
        decimal_value += digit * source_multiplier;
        source_multiplier *= source_base;
        encoded /= 10;
    }

    int64_t result = 0;
    int64_t destination_multiplier = 1;
    while (decimal_value > 0) {
        const int64_t digit = decimal_value % destination_base;
        result += digit * destination_multiplier;
        decimal_value /= destination_base;
        if (decimal_value > 0) {
            if (destination_multiplier > MAX_ENCODED_VALUE / 10) return -1;
            destination_multiplier *= 10;
        }
    }
    return result;
}
