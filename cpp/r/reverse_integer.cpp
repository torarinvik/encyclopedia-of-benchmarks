// Reverse a signed 32-bit decimal integer, returning zero on overflow.
#include <cstdint>

namespace { constexpr std::int64_t invalid_result = -2147483649LL; }

extern "C" std::int64_t reverse_integer(std::int64_t input) noexcept {
    if (input < -2147483648LL || input > 2147483647LL) return invalid_result;
    std::int64_t reversed = 0;
    while (input != 0) {
        const std::int64_t digit = input % 10;
        input /= 10;
        if (reversed > 214748364 || (reversed == 214748364 && digit > 7)) return 0;
        if (reversed < -214748364 || (reversed == -214748364 && digit < -8)) return 0;
        reversed = reversed * 10 + digit;
    }
    return reversed;
}
