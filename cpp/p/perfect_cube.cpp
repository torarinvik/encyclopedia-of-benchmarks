/* Test whether a signed value is an exact integer cube. */
#include <cstdint>

extern "C" std::int64_t perfect_cube(std::int64_t value) noexcept
{
    if (value < -1000000000000LL || value > 1000000000000LL) return -1;
    const std::int64_t target = value < 0 ? -value : value;
    std::int64_t low = 0;
    std::int64_t high = 10000;
    while (low <= high) {
        const std::int64_t middle = low + (high - low) / 2;
        const std::int64_t cube = middle * middle * middle;
        if (cube == target) return 1;
        if (cube < target) low = middle + 1;
        else high = middle - 1;
    }
    return 0;
}
