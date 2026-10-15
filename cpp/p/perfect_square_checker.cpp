/* Check whether a signed 32-bit integer is a perfect square. */
#include <cstdint>

extern "C" std::int64_t perfect_square_checker(std::int64_t n) noexcept
{
    if (n < INT32_MIN || n > INT32_MAX) return -1;
    if (n < 0) return 0;

    std::int64_t low = 0;
    std::int64_t high = 46340;
    while (low <= high) {
        const std::int64_t mid = low + (high - low) / 2;
        const std::int64_t square = mid * mid;
        if (square == n) return 1;
        if (square < n) low = mid + 1;
        else high = mid - 1;
    }
    return 0;
}
