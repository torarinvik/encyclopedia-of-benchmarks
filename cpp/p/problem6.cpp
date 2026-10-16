#include <cstdint>

extern "C" std::int64_t problem6(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > 100) return -1;
    std::int64_t sum = 0;
    std::int64_t sum_of_squares = 0;
    for (std::int64_t value = 1; value <= limit; ++value) {
        sum += value;
        sum_of_squares += value * value;
    }
    return sum * sum - sum_of_squares;
}
