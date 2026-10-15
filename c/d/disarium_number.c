/* Sum decimal digits raised to their one-based positions from the left. */
#include <stdint.h>

int64_t disarium_number(int64_t number)
{
    if (number < 1 || number > 99999999) return -1;
    int64_t digits = 0;
    for (int64_t remaining = number; remaining > 0; remaining /= 10) ++digits;
    int64_t position = digits;
    int64_t remaining = number;
    int64_t sum = 0;
    while (remaining > 0) {
        const int64_t digit = remaining % 10;
        int64_t power = 1;
        for (int64_t exponent = 0; exponent < position; ++exponent) power *= digit;
        sum += power;
        --position;
        remaining /= 10;
    }
    return sum == number ? 1 : 0;
}
