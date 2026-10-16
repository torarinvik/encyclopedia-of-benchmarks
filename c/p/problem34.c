/* Sum numbers equal to the factorial sum of their decimal digits. */
#include <stdint.h>

static int64_t digit_factorial(int64_t digit)
{
    static const int64_t factorials[10] = {1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880};
    return factorials[digit];
}

int64_t problem34(int64_t ignored)
{
    if (ignored != 0) return -1;
    int64_t total = 0;
    for (int64_t number = 3; number <= 2540160; ++number) {
        int64_t remaining = number;
        int64_t digit_sum = 0;
        while (remaining > 0) {
            digit_sum += digit_factorial(remaining % 10);
            remaining /= 10;
        }
        if (digit_sum == number) total += number;
    }
    return total;
}
