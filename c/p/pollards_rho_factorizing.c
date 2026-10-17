#include <stdint.h>

#define MIN_N INT64_C(2)
#define MAX_N INT64_C(46340)

static int64_t next_value(int64_t n, int64_t x) {
    return (x * x + 1) % n;
}

static int64_t gcd_nonnegative(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t pollards_rho_factorizing(int64_t n) {
    if (n < MIN_N || n > MAX_N) return -1;
    int64_t x = 2, y = 2, divisor = 1;
    while (divisor == 1) {
        x = next_value(n, x);
        y = next_value(n, next_value(n, y));
        const int64_t difference = x >= y ? x - y : y - x;
        divisor = gcd_nonnegative(difference, n);
    }
    return divisor;
}
