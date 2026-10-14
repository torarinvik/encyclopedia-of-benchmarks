/* Portable factorial for the shared signed 64-bit benchmark contract. */
#include <cstdint>

extern "C" std::int64_t factorial(std::int64_t n) noexcept
{
    if (n < 0 || n > 20) {
        return -1;
    }

    std::int64_t product = 1;
    for (std::int64_t factor = 2; factor <= n; ++factor) {
        product *= factor;
    }
    return product;
}
