#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_multiplier = 950560;

bool is_prime(std::int64_t value) noexcept
{
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

bool has_prime_factors(std::int64_t n, std::int64_t multiplier) noexcept
{
    if (!is_prime(6 * multiplier + 1) || !is_prime(12 * multiplier + 1)) return false;
    const std::int64_t base = 9 * multiplier;
    for (std::int64_t exponent = 1; exponent <= n - 2; ++exponent) {
        if (!is_prime(base * (std::int64_t{1} << exponent) + 1)) return false;
    }
    return true;
}
} // namespace

extern "C" std::int64_t chernick_carmichael_least_multiplier(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 1) return -1;
    const std::int64_t n = input[0];
    if (n < 3 || n > 9) return -1;

    std::int64_t step = 1;
    if (n > 4) step = std::int64_t{1} << (n - 4);
    if (n > 5) step *= 5;

    for (std::int64_t multiplier = step; multiplier <= max_multiplier;
         multiplier += step) {
        if (has_prime_factors(n, multiplier)) return multiplier;
    }
    return -1;
}
