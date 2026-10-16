/* Count binomial coefficients over the source's 1..100 by 1..n domain. */
#include <stdint.h>
int64_t problem53(int64_t unused) {
    if (unused != 0) return -1;
    int64_t total = 0;
    for (int n = 1; n <= 100; ++n) {
        int64_t coefficient = 1;
        for (int r = 1; r <= n / 2; ++r) {
            coefficient = coefficient * (n - r + 1) / r;
            if (coefficient > 1000000) { total += n - 2 * r + 1; break; }
        }
    }
    return total;
}
