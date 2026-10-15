#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binomial_calculate(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 2) return -1;
    std::int64_t n = input[0], k = input[1];
    if (n < 0 || n > 62 || k < 0 || k > n) return -1;
    if (k > n / 2) k = n - k;
    std::uint64_t result = 1;
    for (std::int64_t i = 1; i <= k; ++i) {
        result *= static_cast<std::uint64_t>(n - k + i);
        result /= static_cast<std::uint64_t>(i);
    }
    return static_cast<std::int64_t>(result);
}
