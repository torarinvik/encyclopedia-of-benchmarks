// Bit spreading for the pinned positive 32-bit source domain.
#include <cstdint>

extern "C" std::int64_t next_power_of_two(std::int64_t number) noexcept
{
    if (number < 1 || number > 1'073'741'824) return -1;
    auto value = static_cast<std::uint64_t>(number);
    if ((value & (value - 1)) == 0) return number;

    --value;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return static_cast<std::int64_t>(value + 1);
}
