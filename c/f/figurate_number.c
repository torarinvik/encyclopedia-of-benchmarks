/* Pack triangular, tetrahedral, and pentatope membership bits. */
#include <stdint.h>

static int is_triangular(int64_t n)
{
    for (int64_t i = 0; i <= n; ++i) {
        const int64_t term = i * (i + 1) / 2;
        if (term == n) return 1;
        if (term > n) return 0;
    }
    return 0;
}

static int is_tetrahedral(int64_t n)
{
    for (int64_t i = 1; i <= n; ++i) {
        const int64_t term = i * (i + 1) * (i + 2) / 6;
        if (term == n) return 1;
        if (term > n) return 0;
    }
    return 0;
}

static int is_pentatope(int64_t n)
{
    for (int64_t i = 1; i <= n; ++i) {
        const int64_t term = i * (i + 1) * (i + 2) * (i + 3) / 24;
        if (term == n) return 1;
        if (term > n) return 0;
    }
    return 0;
}

int64_t figurate_number(int64_t n)
{
    if (n < 0 || n > 1000000) return -1;
    return (is_triangular(n) ? 1 : 0)
        + (is_tetrahedral(n) ? 2 : 0)
        + (is_pentatope(n) ? 4 : 0);
}
