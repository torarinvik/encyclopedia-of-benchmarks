#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -1;
}

extern "C" std::int64_t bcd_conversion(std::int64_t decimal) noexcept
{
    if (decimal < 0 || decimal > 9999) return INVALID_RESULT;
    std::int64_t bcd = 0;
    std::int64_t shift = 0;
    while (decimal > 0) {
        const std::int64_t digit = decimal % 10;
        bcd |= digit << (shift * 4);
        decimal /= 10;
        ++shift;
    }
    return bcd;
}
