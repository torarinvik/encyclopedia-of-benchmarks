#include <cstdint>

extern "C" std::int64_t max_69_number(std::int64_t value) noexcept
{
    if (value < 1 || value > INT64_C(999999999999999999)) return -1;
    std::int64_t place = 1;
    while (place <= value / 10) place *= 10;
    while (place > 0) {
        const std::int64_t digit = (value / place) % 10;
        if (digit == 6) return value + 3 * place;
        if (digit != 9) return -1;
        place /= 10;
    }
    return -1;
}
