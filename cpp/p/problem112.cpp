#include <cstdint>

static bool is_bouncy(std::int64_t value) noexcept
{
    bool increasing = false, decreasing = false;
    auto previous = value % 10;
    value /= 10;
    while (value > 0) {
        const auto digit = value % 10;
        if (digit < previous) increasing = true;
        if (digit > previous) decreasing = true;
        previous = digit;
        value /= 10;
    }
    return increasing && decreasing;
}

extern "C" std::int64_t problem112(std::int64_t percent) noexcept
{
    if (percent < 1 || percent > 99) return -1;
    std::int64_t bouncy = 0;
    for (std::int64_t n = 1; ; ++n) {
        if (is_bouncy(n)) ++bouncy;
        if (bouncy * 100 >= percent * n) return n;
    }
}
