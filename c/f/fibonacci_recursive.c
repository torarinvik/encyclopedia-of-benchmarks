/* Naive recursive Fibonacci on a deliberately small domain. */
#include <stdint.h>

static int64_t fibonacci_value(int64_t n)
{
    if (n < 2) return n;
    return fibonacci_value(n - 1) + fibonacci_value(n - 2);
}

int64_t fibonacci_recursive(int64_t n)
{
    if (n < 0 || n > 30) return -1;
    return fibonacci_value(n);
}
