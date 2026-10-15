#include <stdint.h>

static int is_prime_i64(int64_t n) {
    if (n < 2) return 0;
    if (n % 2 == 0) return n == 2;
    for (int64_t factor = 3; factor <= n / factor; factor += 2) {
        if (n % factor == 0) return 0;
    }
    return 1;
}

int64_t mersenne_prime(int64_t n) {
    if (n == 0) return 0;
    if (n < 0 || n > INT32_MAX) return -1;
    int64_t remaining = n + 1;
    while (remaining % 2 == 0) remaining /= 2;
    if (remaining != 1) return 0;
    return is_prime_i64(n);
}
