#include <cstdint>

namespace {
constexpr std::int64_t MAX_DIGITS = 9;

bool is_prime(std::int64_t number) noexcept
{
    if (number < 2) return false;
    if (number < 4) return true;
    if (number % 2 == 0 || number % 3 == 0) return false;
    for (std::int64_t divisor = 5; divisor <= number / divisor; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return false;
    }
    return true;
}

std::int64_t search(int digits, int depth, std::uint16_t used,
                    std::int64_t value) noexcept
{
    if (depth == digits) return is_prime(value) ? value : 0;
    std::int64_t best = 0;
    for (int digit = 1; digit <= digits; ++digit) {
        const std::uint16_t bit = static_cast<std::uint16_t>(1u << digit);
        if ((used & bit) != 0) continue;
        const std::int64_t candidate = search(digits, depth + 1,
                                              static_cast<std::uint16_t>(used | bit),
                                              value * 10 + digit);
        if (candidate > best) best = candidate;
    }
    return best;
}
}

extern "C" std::int64_t problem41(std::int64_t digits) noexcept
{
    if (digits < 1 || digits > MAX_DIGITS) return -1;
    return search(static_cast<int>(digits), 0, 0, 0);
}
