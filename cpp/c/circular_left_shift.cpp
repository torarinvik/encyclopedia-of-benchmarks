/* Rotate an unsigned 53-bit integer left by 0 through 53 positions. */
#include <cstdint>

extern "C" std::int64_t circular_left_shift(std::uint64_t value, std::uint64_t shift) noexcept
{
    constexpr std::uint64_t mask = UINT64_C(9007199254740991);
    if (value > mask || shift > 53) return -1;
    const unsigned amount = static_cast<unsigned>(shift);
    const std::uint64_t low = (value & (mask >> amount)) << amount;
    const std::uint64_t high = value >> (53 - amount);
    return static_cast<std::int64_t>(low | high);
}
