// Return 1 when a nonnegative integer has an even popcount.
#include <cstdint>

extern "C" std::int64_t evil_number(std::int64_t value)
{
    if (value < 0) return -1;
    std::int64_t count = 0;
    while (value > 0) {
        count += value & 1;
        value >>= 1;
    }
    return count % 2 == 0 ? 1 : 0;
}
