// Check whether n is the product of two consecutive nonnegative integers.
#include <cmath>
#include <cstdint>

extern "C" std::int64_t pronic_number(std::int64_t n) noexcept {
    if (n < 0 || n > INT32_MAX) return -1;
    const std::int64_t root = static_cast<std::int64_t>(std::sqrt(static_cast<double>(n)));
    return root * (root + 1) == n ? 1 : 0;
}
