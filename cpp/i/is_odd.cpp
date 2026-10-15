/* Return 1 for an odd signed 64-bit integer and 0 for an even one. */
#include <cstdint>

extern "C" std::int64_t is_odd(std::int64_t value) noexcept
{
    return value % 2 != 0 ? 1 : 0;
}
