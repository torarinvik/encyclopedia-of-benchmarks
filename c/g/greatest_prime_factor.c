/* Greatest prime factor over the bounded primelib input domain. */
#include <stdint.h>

static int is_prime_trial(int64_t value)
{
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t greatest_prime_factor(int64_t n)
{
    if (n < 0 || n > 1000000) return -1;
    if (n < 2) return n;
    if (is_prime_trial(n)) return n;

    int64_t quotient = n;
    int64_t largest = 0;
    int64_t factor = 2;
    while (quotient != 1) {
        if (is_prime_trial(factor) && quotient % factor == 0) {
            largest = factor;
            quotient /= factor;
        } else {
            ++factor;
        }
    }
    return largest;
}
