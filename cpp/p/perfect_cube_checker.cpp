/* Check whether a signed 32-bit integer is a perfect cube. */
#include <cstdint>

extern "C" std::int64_t perfect_cube_checker(std::int64_t n) noexcept
{
    if (n < INT32_MIN || n > INT32_MAX) return -1;

    const std::int64_t magnitude = n < 0 ? -n : n;
    std::int64_t low = 0;
    std::int64_t high = 1290;
    while (low <= high) {
        const std::int64_t mid = low + (high - low) / 2;
        const std::int64_t cube = mid * mid * mid;
        if (cube == magnitude) return 1;
        if (cube < magnitude) low = mid + 1;
        else high = mid - 1;
    }
    return 0;
}
