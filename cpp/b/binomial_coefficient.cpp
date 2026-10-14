/* Calculate C(n, k) by updating one row of Pascal's triangle. */
#include <cstdint>

extern "C" std::int64_t binomial_coefficient(std::uint64_t n, std::uint64_t k) noexcept
{
    if (n > 66) return -1;
    if (k > n) return 0;
    if (k == 0) return 1;
    std::int64_t coefficients[67]{};
    coefficients[0] = 1;
    for (std::uint64_t row = 1; row <= n; ++row) {
        std::uint64_t column = row < k ? row : k;
        while (column > 0) {
            coefficients[column] += coefficients[column - 1];
            --column;
        }
    }
    return coefficients[k];
}
