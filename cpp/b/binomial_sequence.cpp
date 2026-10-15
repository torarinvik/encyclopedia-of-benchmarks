#include <cstdint>

namespace {
constexpr std::int64_t max_index = 230;

std::int64_t binomial_coefficient(std::int64_t n, std::int64_t k)
{
    if (k == 0 || k == n) return 1;
    if (n < 0) return 0;
    return binomial_coefficient(n - 1, k) + binomial_coefficient(n - 1, k - 1);
}
}

extern "C" std::int64_t binomial_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index > max_index) return -1;
    std::int64_t row = 0;
    std::int64_t row_start = 0;
    while (index >= row_start + row + 1) {
        row_start += row + 1;
        ++row;
    }
    return binomial_coefficient(row, index - row_start);
}
