#include <cstdint>

extern "C" std::int64_t rotate_left32(std::uint64_t value, std::uint64_t shift) noexcept
{
    if (value > UINT32_MAX || shift > INT32_MAX) return -1;
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    const std::uint32_t amount = static_cast<std::uint32_t>(shift % 32);
    if (amount == 0) return static_cast<std::int64_t>(bits);
    return static_cast<std::int64_t>((bits << amount) | (bits >> (32 - amount)));
}
