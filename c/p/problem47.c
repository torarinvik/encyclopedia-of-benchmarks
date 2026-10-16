/* First run of n consecutive integers with n distinct prime factors each. */
#include <stdint.h>

static int64_t distinct_prime_factor_count(int64_t value)
{
    int64_t count = 0;
    for (int64_t divisor = 2; divisor * divisor <= value; ++divisor) {
        if (value % divisor == 0) {
            ++count;
            do {
                value /= divisor;
            } while (value % divisor == 0);
        }
    }
    if (value > 1) ++count;
    return count;
}

int64_t problem47(int64_t n)
{
    if (n < 1 || n > 4) return -1;
    int64_t run_length = 0;
    for (int64_t value = 2; ; ++value) {
        if (distinct_prime_factor_count(value) == n) ++run_length;
        else run_length = 0;
        if (run_length == n) return value - n + 1;
    }
}
