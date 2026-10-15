#include <stdint.h>

#define MAX_INDEX INT64_C(230)

static int64_t binomial_coefficient(int64_t n, int64_t k)
{
    if (k == 0 || k == n) return 1;
    if (n < 0) return 0;
    return binomial_coefficient(n - 1, k) + binomial_coefficient(n - 1, k - 1);
}

int64_t binomial_sequence(int64_t index)
{
    if (index < 0 || index > MAX_INDEX) return -1;
    int64_t row = 0;
    int64_t row_start = 0;
    while (index >= row_start + row + 1) {
        row_start += row + 1;
        ++row;
    }
    return binomial_coefficient(row, index - row_start);
}
