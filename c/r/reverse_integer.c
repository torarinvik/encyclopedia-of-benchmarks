/* Reverse a signed 32-bit decimal integer, returning zero on overflow. */
#include <stdint.h>

#define INVALID_RESULT INT64_C(-2147483649)

int64_t reverse_integer(int64_t input)
{
    if (input < INT32_MIN || input > INT32_MAX) return INVALID_RESULT;
    int64_t reversed = 0;
    while (input != 0) {
        const int64_t digit = input % 10;
        input /= 10;
        if (reversed > INT32_MAX / 10 ||
            (reversed == INT32_MAX / 10 && digit > 7)) return 0;
        if (reversed < INT32_MIN / 10 ||
            (reversed == INT32_MIN / 10 && digit < -8)) return 0;
        reversed = reversed * 10 + digit;
    }
    return reversed;
}
