/* Search the pinned source's descending square-pattern candidates. */
#include <cstdint>

namespace {
constexpr std::int64_t start = 138'902'663;
constexpr std::int64_t minimum = 101'010'103;

bool is_square_form(std::int64_t value) noexcept
{
    std::int64_t digit = 9;
    while (value > 0) {
        if (value % 10 != digit) return false;
        value /= 100;
        --digit;
    }
    return true;
}
}

extern "C" std::int64_t problem206(std::int64_t unused) noexcept
{
    if (unused != 0) return -1;
    auto candidate = start;
    while (candidate >= minimum) {
        if (is_square_form(candidate * candidate)) return candidate * 10;
        candidate -= candidate % 10 == 3 ? 6 : 4;
    }
    return -1;
}
