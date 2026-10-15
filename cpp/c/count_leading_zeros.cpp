#include <cstdint>
#include <limits>

extern "C" std::int64_t count_leading_zeros(std::int64_t value) noexcept
{
    if (value < std::numeric_limits<std::int32_t>::min() ||
        value > std::numeric_limits<std::int32_t>::max()) return -1;
    if (value == 0) return 32;
    std::int64_t mask = std::int64_t{1} << 31;
    std::int64_t count = 0;
    while ((mask & value) == 0) {
        ++count;
        mask >>= 1;
    }
    return count;
}
