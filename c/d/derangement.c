/* Return the source-compatible derangement count for n in 0..=20. */
#include <stdint.h>

int64_t derangement(int64_t n)
{
    if (n < 0 || n > 20) return -1;
    if (n < 2) return 0;
    if (n == 2) return 1;

    int64_t previous = 1;      /* D(2) */
    int64_t previous_previous = 0; /* D(1) */
    for (int64_t i = 3; i <= n; ++i) {
        const int64_t current = (i - 1) * (previous + previous_previous);
        previous_previous = previous;
        previous = current;
    }
    return previous;
}
