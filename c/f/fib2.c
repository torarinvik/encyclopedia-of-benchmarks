/* Shootout fib2: uncached recursion with fib(0) = fib(1) = 1. */
#include <stdint.h>

static int64_t fib2_value(int64_t n)
{
    if (n < 2) return 1;
    return fib2_value(n - 2) + fib2_value(n - 1);
}

int64_t fib2(int64_t n)
{
    if (n < 0 || n > 30) return -1;
    return fib2_value(n);
}
