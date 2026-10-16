#include <cstdint>

namespace {
constexpr std::int64_t MAX_LIMIT = 1'000'000;

bool is_decimal_palindrome(std::int64_t value) noexcept
{
    std::int64_t remaining = value;
    std::int64_t reversed = 0;
    while (remaining > 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
    }
    return reversed == value;
}

bool is_binary_palindrome(std::int64_t value) noexcept
{
    std::int64_t remaining = value;
    std::int64_t reversed = 0;
    while (remaining > 0) {
        reversed = reversed * 2 + remaining % 2;
        remaining /= 2;
    }
    return reversed == value;
}
}

extern "C" std::int64_t problem36(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    std::int64_t total = 0;
    for (std::int64_t value = 1; value < limit; ++value) {
        if (is_decimal_palindrome(value) && is_binary_palindrome(value)) total += value;
    }
    return total;
}
