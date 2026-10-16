#include <array>
#include <cstdint>

extern "C" std::int64_t problem16(std::int64_t exponent) noexcept
{
    if (exponent < 0 || exponent > 1000) return -1;
    std::array<int, 400> digits{};
    digits[0] = 1;
    int length = 1;
    for (std::int64_t power = 0; power < exponent; ++power) {
        int carry = 0;
        for (int index = 0; index < length; ++index) {
            const int value = digits[static_cast<std::size_t>(index)] * 2 + carry;
            digits[static_cast<std::size_t>(index)] = value % 10;
            carry = value / 10;
        }
        while (carry > 0) {
            digits[static_cast<std::size_t>(length++)] = carry % 10;
            carry /= 10;
        }
    }
    std::int64_t sum = 0;
    for (int index = 0; index < length; ++index)
        sum += digits[static_cast<std::size_t>(index)];
    return sum;
}
