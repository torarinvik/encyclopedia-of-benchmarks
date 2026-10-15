// Return the zero-based index of the most significant set bit.
#include <cstdint>

extern "C" std::int64_t highest_set_bit(std::int64_t value)
{
    if (value <= 0) return -1;
    std::int64_t position = -1;
    while (value > 0) {
        ++position;
        value >>= 1;
    }
    return position;
}
