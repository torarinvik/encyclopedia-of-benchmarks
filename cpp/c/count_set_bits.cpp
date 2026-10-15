#include <cstdint>

namespace {
constexpr std::int64_t MAX_INPUT = 67108863;

int highest_power_position(std::int64_t value)
{
    int position = 0;
    std::int64_t power = 1;
    while (power <= value / 2) {
        power *= 2;
        ++position;
    }
    return position;
}

std::int64_t count_set_bits_recursive(std::int64_t value)
{
    if (value == 0) return 0;
    const int position = highest_power_position(value);
    const std::int64_t power = std::int64_t{1} << position;
    const std::int64_t bits_at_position = position == 0 ? 0 : position * (power >> 1);
    const std::int64_t remaining_numbers = value - power + 1;
    return bits_at_position + remaining_numbers + count_set_bits_recursive(value - power);
}
}

// Total set bits in every integer from 1 through value, inclusive.
extern "C" std::int64_t count_set_bits(std::int64_t value) noexcept
{
    if (value < 0 || value > MAX_INPUT) return -1;
    return count_set_bits_recursive(value);
}
