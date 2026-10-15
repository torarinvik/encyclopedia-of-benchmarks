// Check the Fibonacci square identity without overflowing signed 64-bit values.
#include <cstdint>

static bool square_i64(std::int64_t value) noexcept
{
    if (value < 0) return false;
    std::int64_t low = 0;
    std::int64_t high = 3037000499;
    while (low <= high) {
        const auto middle = low + (high - low) / 2;
        const auto square = middle * middle;
        if (square == value) return true;
        if (square < value) low = middle + 1;
        else high = middle - 1;
    }
    return false;
}

extern "C" std::int64_t fibonacci_number_check(std::int64_t number) noexcept
{
    if (number < -1300000000LL || number > 1300000000LL) return -1;
    const auto value = 5 * number * number;
    return square_i64(value + 4) || square_i64(value - 4) ? 1 : 0;
}
