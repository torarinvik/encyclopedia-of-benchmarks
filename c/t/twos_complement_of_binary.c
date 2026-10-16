#include <stdint.h>

#define MAX_BINARY_DIGIT_NUMERAL INT64_C(1111111111111111)

int64_t twos_complement_of_binary(int64_t value)
{
    if (value < 0 || value > MAX_BINARY_DIGIT_NUMERAL) return -1;
    if (value == 0) return 0;

    int64_t remaining = value;
    while (remaining > 0) {
        const int64_t digit = remaining % 10;
        if (digit != 0 && digit != 1) return -1;
        remaining /= 10;
    }

    remaining = value;
    int64_t reversed = 0;
    int64_t width = 0;
    while (remaining > 0 && remaining % 10 == 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        ++width;
    }
    if (remaining > 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        ++width;
    }
    while (remaining > 0) {
        const int64_t digit = remaining % 10;
        reversed = reversed * 10 + (digit == 1 ? 0 : 1);
        remaining /= 10;
        ++width;
    }

    int64_t result = 0;
    while (width > 0) {
        result = result * 10 + reversed % 10;
        reversed /= 10;
        --width;
    }
    return result;
}
