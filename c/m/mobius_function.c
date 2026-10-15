/* Return the Möbius function for a bounded positive integer. */
#include <stdint.h>

int64_t mobius_function(int64_t n)
{
    if (n < 1 || n > 10000) return INT64_MIN;
    int64_t remaining = n;
    int64_t distinct_factor_count = 0;
    for (int64_t factor = 2; factor * factor <= remaining; ++factor) {
        if (remaining % factor == 0) {
            remaining /= factor;
            if (remaining % factor == 0) return 0;
            ++distinct_factor_count;
        }
    }
    if (remaining > 1) ++distinct_factor_count;
    return distinct_factor_count % 2 == 0 ? 1 : -1;
}
