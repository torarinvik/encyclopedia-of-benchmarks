// Return the one-based position of the least significant set bit.
#include <cstdint>

extern "C" std::int64_t rightmost_set_bit(std::int64_t value)
{
    if (value <= 0 || value > INT32_MAX) return -1;
    std::uint32_t lowest = static_cast<std::uint32_t>(value) &
                           (0u - static_cast<std::uint32_t>(value));
    std::int64_t position = 1;
    while ((lowest & 1u) == 0u) {
        lowest >>= 1;
        ++position;
    }
    return position;
}
