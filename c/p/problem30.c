/* Sum fixed-range numbers equal to the fifth powers of their decimal digits. */
#include <stdint.h>

static int64_t digit_fifth_power(int64_t digit)
{
    return digit * digit * digit * digit * digit;
}

int64_t problem30(int64_t ignored)
{
    if (ignored != 0) return -1;
    int64_t total = 0;
    for (int64_t number = 1000; number < 1000000; ++number) {
        int64_t remaining = number;
        int64_t digit_sum = 0;
        while (remaining > 0) {
            digit_sum += digit_fifth_power(remaining % 10);
            remaining /= 10;
        }
        if (digit_sum == number) total += number;
    }
    return total;
}
