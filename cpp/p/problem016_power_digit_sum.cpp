/* Decimal digit sum of a bounded single-digit base power. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t problem016_power_digit_sum(const std::int64_t *values,
                                                    std::size_t length) noexcept
{
    if (values == nullptr || length != 2) return -1;
    const std::int64_t base = values[0];
    const std::int64_t exponent = values[1];
    if (base < 0 || base > 9 || exponent < 0 || exponent > 1000) return -1;

    std::int64_t digits[1001] = {};
    std::size_t digit_count = 1;
    digits[0] = base;

    for (std::int64_t power = 1; power < exponent; ++power) {
        std::int64_t carry = 0;
        for (std::size_t index = 0; index < digit_count; ++index) {
            const std::int64_t product = digits[index] * base + carry;
            digits[index] = product % 10;
            carry = product / 10;
        }
        while (carry > 0) {
            if (digit_count >= 1001) return -1;
            digits[digit_count++] = carry % 10;
            carry /= 10;
        }
    }

    std::int64_t sum = 0;
    for (std::size_t index = 0; index < digit_count; ++index) sum += digits[index];
    return sum;
}
