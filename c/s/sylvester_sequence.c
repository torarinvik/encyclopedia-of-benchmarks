/* Recursive Sylvester recurrence on the signed 64-bit benchmark domain. */
#include <stdint.h>

static int64_t sylvester_term(int64_t n)
{
    if (n == 1) return 2;
    const int64_t previous = sylvester_term(n - 1);
    return previous * (previous - 1) + 1;
}

int64_t sylvester_sequence(int64_t n)
{
    if (n < 1 || n > 7) return -1;
    return sylvester_term(n);
}
