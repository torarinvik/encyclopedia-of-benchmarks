#include <cstdint>

namespace {
constexpr std::uint64_t MAX_U53 = UINT64_C(9007199254740991);
constexpr std::int64_t INVALID_RESULT = -1;
}

extern "C" std::int64_t arithmetic_left_shift(std::uint64_t n, std::uint64_t shift) noexcept
{
    if (n > MAX_U53 || shift > 53) return INVALID_RESULT;
    return static_cast<std::int64_t>((n << static_cast<unsigned>(shift)) & MAX_U53);
}
