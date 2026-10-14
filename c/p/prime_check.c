/* Trial-division primality check over the shared bounded integer domain. */
#include <stdint.h>

int64_t prime_check(int64_t n)
{
    if (n < 2) return 0;
    if (n > INT32_MAX) return -1;
    if (n % 2 == 0) return n == 2;
    for (int64_t factor = 3; factor <= n / factor; factor += 2) {
        if (n % factor == 0) return 0;
    }
    return 1;
}
