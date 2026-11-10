/* Test whether a signed value is an exact integer cube. */
#include <cstdint>

extern "C" std::int64_t perfect_cube(std::int64_t value) noexcept
{
    if (value < -1000000000000LL || value > 1000000000000LL) return -1;
    const std::uint64_t target = static_cast<std::uint64_t>(value < 0 ? -value : value);
    if (target < 2) return 1;
    const std::uint64_t root_limit = target <= 1000 ? 10 : target <= 1000000 ? 100 : target <= 1000000000 ? 1000 : 10000;
    std::uint64_t low = 1;
    std::uint64_t high = target / 2 < root_limit ? target / 2 : root_limit;
    while (low <= high) {
        const std::uint64_t middle = (low + high) >> 1;
        const std::uint64_t cube = middle * middle * middle;
        if (cube == target) return 1;
        if (cube < target) {
            if (middle == high) return 0;
            low = middle + 1;
        } else {
            if (middle == low) return 0;
            high = middle - 1;
        }
    }
    return 0;
}
