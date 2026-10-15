#include <cstdint>

namespace {
constexpr std::uint64_t MAX_U53 = UINT64_C(9007199254740991);
constexpr std::int64_t INVALID_RESULT = -1;
}

extern "C" std::int64_t arithmetic_right_shift(std::uint64_t n, std::uint64_t shift) noexcept
{
    if (n > MAX_U53 || shift > 53) return INVALID_RESULT;
    const unsigned count = static_cast<unsigned>(shift);
    const std::uint64_t low_mask = (UINT64_C(1) << (53U - count)) - UINT64_C(1);
    const std::uint64_t fill_mask = (n >> 52) != 0 ? (MAX_U53 ^ low_mask) : UINT64_C(0);
    return static_cast<std::int64_t>(fill_mask | (n >> count));
}
