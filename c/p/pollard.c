#include <stddef.h>
#include <stdint.h>

#define MIN_N INT64_C(2)
#define MAX_N INT64_C(111155)

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

int64_t pollard(const int64_t *input, size_t length) {
    if (input == NULL || length != 1) return -1;
    const int64_t n = input[0];
    if (n < MIN_N || n > MAX_N) return -1;

    int64_t x = 2;
    int64_t y = 2;
    int64_t divisor = 1;
    while (divisor == 1) {
        x = next_value(n, x);
        y = next_value(n, next_value(n, y));
        int64_t difference = x - y;
        if (difference < 0) difference = -difference;
        divisor = gcd_nonnegative(difference, n);
    }
    return divisor == n ? 0 : divisor;
}
