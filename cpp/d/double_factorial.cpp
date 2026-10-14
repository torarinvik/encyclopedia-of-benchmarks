/* Iterative double factorial for the signed 64-bit benchmark contract. */
#include <cstdint>

extern "C" std::int64_t double_factorial(std::int64_t n) noexcept
{
    if (n < 0 || n > 33) return -1;
    std::int64_t result = 1;
    for (auto factor = n; factor > 1; factor -= 2) result *= factor;
    return result;
}
