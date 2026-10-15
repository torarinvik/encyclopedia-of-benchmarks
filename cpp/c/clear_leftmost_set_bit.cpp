#include <cstdint>
#include <limits>

extern "C" std::int64_t clear_leftmost_set_bit(std::int64_t value) noexcept
{
    if (value < 0 || value > std::numeric_limits<std::int32_t>::max()) return -1;
    if (value == 0) return 0;
    std::int64_t temp = value;
    std::int64_t position = 0;
    while (temp > 0) {
        temp >>= 1;
        ++position;
    }
    const std::int64_t mask = ~(std::int64_t{1} << (position - 1));
    return value & mask;
}
