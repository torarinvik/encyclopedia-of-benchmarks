#include <stddef.h>
#include <stdint.h>

#define MIN_N INT64_C(2)
#define MAX_N INT64_C(46340)
#define MAX_STEPS INT64_C(4096)

static int64_t java_remainder(int64_t value, int64_t modulus) {
    return value < 0 ? -((-value) % modulus) : value % modulus;
}

static int64_t next_value(int64_t value, int64_t modulus) {
    return java_remainder(value * value - 1, modulus);
}

static int64_t gcd_nonnegative(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t pollard_rho_java(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t n = input[0];
    const int64_t step_limit = input[1];
    if (n < MIN_N || n > MAX_N || step_limit < 1 || step_limit > MAX_STEPS) return -1;

    int64_t x = 2;
    int64_t y = 2;
    for (int64_t step = 0; step < step_limit; ++step) {
        x = next_value(x, n);
        y = next_value(next_value(y, n), n);
        const int64_t difference = x >= y ? x - y : y - x;
        const int64_t divisor = gcd_nonnegative(difference, n);
        if (divisor == 1) continue;
        return divisor == n ? 0 : divisor;
    }
    return -2;
}
