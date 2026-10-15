#include <cstdint>

extern "C" std::int64_t sum_of_odd_numbers(std::int64_t n) noexcept
{
    if (n < 0 || n > 46340) return -1;
    return n * n;
}
