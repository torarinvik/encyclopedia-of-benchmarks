#include <cstdint>
#include <limits>

extern "C" std::int64_t count_leading_zeros(std::int64_t value) noexcept
{
    if (value < std::numeric_limits<std::int32_t>::min() ||
        value > std::numeric_limits<std::int32_t>::max()) return -1;
    const auto bits = static_cast<std::uint32_t>(value);
    return bits == 0 ? 32 : __builtin_clz(bits);
}
