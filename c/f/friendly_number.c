#include <stdint.h>

static int64_t sum_divisors(uint64_t number)
{
    int64_t sum = 0;
    for (uint64_t divisor = 1; divisor * divisor <= number; ++divisor) {
        if (number % divisor == 0) {
            sum += (int64_t)divisor;
            uint64_t other = number / divisor;
            if (other != divisor) sum += (int64_t)other;
        }
    }
    return sum;
}

int64_t friendly_number(uint64_t a, uint64_t b)
{
    if (a > 1000000 || b > 1000000) return -1;
    if (a == 0 || b == 0) return 0;
    int64_t sigma_a = sum_divisors(a), sigma_b = sum_divisors(b);
    return sigma_a * (int64_t)b == sigma_b * (int64_t)a ? 1 : 0;
}
