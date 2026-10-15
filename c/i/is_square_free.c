/* Return whether positive n has no repeated prime factor. */
#include <stdint.h>

int64_t is_square_free(int64_t n)
{
    if (n < 1 || n > 1000000) return -1;
    for (int64_t factor = 2; factor <= n / factor; ++factor) {
        if (n % factor == 0) {
            n /= factor;
            if (n % factor == 0) return 0;
        }
    }
    return 1;
}
