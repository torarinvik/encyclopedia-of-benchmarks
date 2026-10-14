/* Return 1 for an even signed 64-bit integer and 0 for an odd one. */
#include <cstdint>

extern "C" std::int64_t is_even(std::int64_t value) noexcept
{
    return value % 2 == 0 ? 1 : 0;
}
