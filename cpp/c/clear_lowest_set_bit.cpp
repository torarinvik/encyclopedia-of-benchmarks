#include <cstdint>
#include <limits>

extern "C" std::int64_t clear_lowest_set_bit(std::int64_t value) noexcept
{
    if (value < 0 || value > std::numeric_limits<std::int32_t>::max()) return -1;
    return value & (value - 1);
}
