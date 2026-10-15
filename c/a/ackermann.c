/* Bounded recursive Ackermann function A(m, n). */
#include <stdint.h>

static int64_t ackermann_value(int64_t m, int64_t n)
{
    if (m == 0) return n + 1;
    if (n == 0) return ackermann_value(m - 1, 1);
    return ackermann_value(m - 1, ackermann_value(m, n - 1));
}

int64_t ackermann(int64_t m, int64_t n)
{
    if (m < 0 || m > 3 || n < 0 || n > 5) return -1;
    return ackermann_value(m, n);
}
