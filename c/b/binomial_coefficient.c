/* Calculate C(n, k) by updating one row of Pascal's triangle. */
#include <stdint.h>

int64_t binomial_coefficient(uint64_t n, uint64_t k)
{
    if (n > 66) return -1;
    if (k > n) return 0;
    if (k == 0) return 1;
    int64_t coefficients[67] = {0};
    coefficients[0] = 1;
    for (uint64_t row = 1; row <= n; ++row) {
        uint64_t column = row < k ? row : k;
        while (column > 0) {
            coefficients[column] += coefficients[column - 1];
            --column;
        }
    }
    return coefficients[k];
}
