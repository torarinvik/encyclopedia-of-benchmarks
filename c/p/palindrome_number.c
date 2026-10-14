/* Reverse half the digits to avoid overflow. */
#include <stdint.h>

int64_t palindrome_number(int64_t value)
{
    if (value < 0 || value > INT32_MAX) return -1;
    if (value != 0 && value % 10 == 0) return 0;
    int64_t remaining = value;
    int64_t reversed_half = 0;
    while (remaining > reversed_half) {
        reversed_half = reversed_half * 10 + remaining % 10;
        remaining /= 10;
    }
    return remaining == reversed_half || remaining == reversed_half / 10;
}
