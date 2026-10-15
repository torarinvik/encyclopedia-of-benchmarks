/* Check whether n equals the sum of each decimal digit raised to digit count. */
#include <stdint.h>

int64_t narcissistic_number_checker(int64_t n)
{
    if (n < INT32_MIN || n > 999999) return -1;

    const int64_t original = n;
    int64_t remaining = n;
    int64_t digits = 0;
    while (remaining != 0) {
        ++digits;
        remaining /= 10;
    }

    int64_t sum = 0;
    while (n > 0) {
        const int64_t digit = n % 10;
        int64_t power = 1;
        for (int64_t exponent = 0; exponent < digits; ++exponent) power *= digit;
        sum += power;
        n /= 10;
    }
    return sum == original ? 1 : 0;
}
