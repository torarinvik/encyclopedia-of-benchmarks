/* Independent portable implementation; upstream references are in the guide. */
#include <stdint.h>

int64_t aliquot_sum(int64_t n)
{
    if (n < 0) return -1;
    int64_t sum = 0;
    for (int64_t divisor = 1; divisor <= n / 2; ++divisor) {
        if (n % divisor == 0) {
            if (sum > INT64_MAX - divisor) return -1;
            sum += divisor;
        }
    }
    return sum;
}
