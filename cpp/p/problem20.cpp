#include <cstdint>

extern "C" std::int64_t problem20(std::int64_t n) noexcept
{
    if (n < 0 || n > 100) return -1;
    int digits[200] = {1};
    int length = 1;
    for (std::int64_t factor = 2; factor <= n; ++factor) {
        std::int64_t carry = 0;
        for (int index = 0; index < length; ++index) {
            const std::int64_t value = static_cast<std::int64_t>(digits[index]) * factor + carry;
            digits[index] = static_cast<int>(value % 10);
            carry = value / 10;
        }
        while (carry > 0) {
            digits[length++] = static_cast<int>(carry % 10);
            carry /= 10;
        }
    }
    std::int64_t sum = 0;
    for (int index = 0; index < length; ++index) sum += digits[index];
    return sum;
}
