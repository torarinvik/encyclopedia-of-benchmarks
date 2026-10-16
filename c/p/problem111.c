#include <stdint.h>

#define MAX_N INT64_C(10000000000)
#define SIEVE_CAP 100002
#define PRIME_CAP 100001

static int is_prime(int64_t value, const int64_t *primes, int count)
{
    for (int i = 0; i < count; ++i) {
        const int64_t p = primes[i];
        if (value == p) return 0;
        if (value % p == 0) return 0;
    }
    return 1;
}

int64_t problem111(int64_t n)
{
    if (n < 1000 || n > MAX_N) return -1;
    int64_t composite[SIEVE_CAP] = {0};
    int64_t primes[PRIME_CAP];
    int prime_count = 0;
    int64_t root = 0;
    while (root + 1 <= n / (root + 1)) ++root;
    const int sieve_limit = (int)root + 1;
    for (int p = 2; p <= sieve_limit; ++p) {
        if (composite[p]) continue;
        primes[prime_count++] = p;
        if ((int64_t)p * p <= sieve_limit)
            for (int multiple = p * p; multiple <= sieve_limit; multiple += p) composite[multiple] = 1;
    }
    int digits = 0; for (int64_t copy = n; copy > 0; copy /= 10) ++digits;
    const int width = digits - 1;
    const int repeated_one = width - 1;
    const int repeated_two = width - 2;
    int64_t total = 0;
    for (int i = 1; i <= 9; ++i) for (int j = 1; j <= 9; ++j) {
        int64_t value = i;
        for (int z = 0; z < width - 2; ++z) value *= 10;
        value = value * 10 + j;
        if (is_prime(value, primes, prime_count)) total += value;
    }
    int one_digit[10] = {0};
    for (int i = 1; i <= 9; ++i) for (int j = 0; j < width; ++j) for (int k = 0; k <= 9; ++k) {
        int64_t value = 0;
        for (int position = 0; position < width; ++position) value = value * 10 + (position == j ? k : i);
        if (is_prime(value, primes, prime_count)) { one_digit[i] = 1; total += value; }
    }
    for (int i = 1; i <= 9; ++i) if (!one_digit[i])
        for (int j = 0; j <= repeated_two; ++j) for (int k = 0; k <= repeated_two - j; ++k)
            for (int m1 = 0; m1 <= 9; ++m1) {
                if (m1 == 0 && j == 0) continue;
                for (int m2 = 0; m2 <= 9; ++m2) {
                    int64_t value = 0;
                    for (int position = 0; position < width; ++position) {
                        int digit = position == j ? m1 : (position == j + k + 1 ? m2 : i);
                        value = value * 10 + digit;
                    }
                    if (is_prime(value, primes, prime_count)) total += value;
                }
            }
    (void)repeated_one;
    return total;
}
