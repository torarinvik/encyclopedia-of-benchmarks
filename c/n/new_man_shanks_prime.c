#include <stdint.h>

#define MAX_INDEX INT64_C(25)
#define INT32_MIN_VALUE (-INT64_C(2147483648))
#define INT32_MAX_VALUE INT64_C(2147483647)

/* Compare the source recurrence term a[n] with expected; no primality test. */
int64_t new_man_shanks_prime(int64_t n, int64_t expected)
{
    if (n < 1 || n > MAX_INDEX || expected < INT32_MIN_VALUE || expected > INT32_MAX_VALUE) return -1;
    int32_t previous_previous = 1;
    int32_t previous = 1;
    if (n == 1) return expected == previous ? 1 : 0;
    for (int64_t index = 2; index <= n; ++index) {
        const int32_t current = 2 * previous + previous_previous;
        previous_previous = previous;
        previous = current;
    }
    return (int64_t)previous == expected ? 1 : 0;
}
