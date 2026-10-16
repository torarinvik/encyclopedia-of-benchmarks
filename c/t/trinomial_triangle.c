#include <stdint.h>

static int64_t trinomial_value(int64_t n, int64_t k)
{
    if (n == 0 && k == 0) return 1;
    if (k < -n || k > n) return 0;
    return trinomial_value(n - 1, k - 1) +
           trinomial_value(n - 1, k) +
           trinomial_value(n - 1, k + 1);
}

int64_t trinomial_triangle(int64_t n, int64_t k)
{
    if (n < 0 || n > 10 || k < -10 || k > 10) return -1;
    return trinomial_value(n, k);
}
