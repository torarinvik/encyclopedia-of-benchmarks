/* Return 1 when n is a positive power of two, otherwise 0. */
#include <cstdint>

extern "C" std::int64_t power_of_two(std::int64_t n) noexcept
{
    if (n <= 0) return 0;
    return (n & (n - 1)) == 0;
}
