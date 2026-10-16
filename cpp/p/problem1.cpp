#include <cstdint>

extern "C" std::int64_t problem1(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 100000) return -1;
    std::int64_t sum = 0;
    for (std::int64_t value = 1; value < limit; ++value)
        if (value % 3 == 0 || value % 5 == 0) sum += value;
    return sum;
}
