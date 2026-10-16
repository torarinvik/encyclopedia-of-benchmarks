/* Count non-bouncy positive integers with at most the requested digits. */
#include <cstdint>

namespace {
constexpr std::int64_t MAX_DIGITS = 100;

std::int64_t choose_integer(std::int64_t n, std::int64_t r) noexcept
{
    std::int64_t result = 1;
    for (std::int64_t i = 1; i <= r; ++i) result = result * (n + 1 - i) / i;
    return result;
}

std::int64_t non_bouncy_exact(std::int64_t digits) noexcept
{
    return choose_integer(8 + digits, digits) + choose_integer(9 + digits, digits) - 10;
}
}

extern "C" std::int64_t problem113(std::int64_t num_digits) noexcept
{
    if (num_digits > MAX_DIGITS) return -1;
    std::int64_t total = 0;
    for (std::int64_t digits = 1; digits <= num_digits; ++digits)
        total += non_bouncy_exact(digits);
    return total;
}
