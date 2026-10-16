/* Preserve the pinned sigma2 behavior, including omission of divisor 1. */
#include <stdint.h>

#define MAX_LIMIT INT64_C(1000)
#define MOD_LIMIT INT64_C(1000000000)
#define DIVISOR_CAPACITY 128

static int contains(int64_t value, const int64_t divisors[DIVISOR_CAPACITY], int64_t length)
{
    for (int64_t i = 0; i < length; ++i) if (divisors[i] == value) return 1;
    return 0;
}
static int64_t get_divisors(int64_t number, int64_t divisors[DIVISOR_CAPACITY])
{
    if (number == 1) { divisors[0] = 1; return 1; }
    int64_t count = 0;
    for (int64_t i = 1; i * i <= number + 1; ++i) {
        if (number % i == 0) {
            const int64_t quotient = number / i;
            if (!contains(i, divisors, count)) divisors[count++] = i;
            if (!contains(quotient, divisors, count)) divisors[count++] = quotient;
        }
    }
    return count;
}
static int64_t sigma2_source(int64_t number)
{
    int64_t divisors[DIVISOR_CAPACITY] = {0};
    const int64_t count = get_divisors(number, divisors);
    int64_t sum = 0;
    for (int64_t i = 1; i < count; ++i) sum += (divisors[i] * divisors[i]) % MOD_LIMIT;
    return sum % MOD_LIMIT;
}

int64_t problem401(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    int64_t sum = 0;
    for (int64_t number = 0; number <= limit; ++number) sum += sigma2_source(number);
    return sum % MOD_LIMIT;
}
