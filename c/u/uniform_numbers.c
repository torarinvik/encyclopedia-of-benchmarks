/* Count positive repdigits up to the input using the pinned prefix formula. */
#include <stdint.h>

int64_t uniform_numbers(int64_t value)
{
    if (value < 0 || value > 999999999) return -1;
    int64_t remaining = value;
    int64_t first_digit = 0;
    int64_t digits = 0;
    do {
        first_digit = remaining % 10;
        remaining /= 10;
        ++digits;
    } while (remaining != 0);
    int64_t repeated = 0;
    for (int64_t index = 0; index < digits; ++index) repeated = repeated * 10 + first_digit;
    int64_t count = (digits - 1) * 9;
    return count + (repeated <= value ? first_digit : first_digit - 1);
}
