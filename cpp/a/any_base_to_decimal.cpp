/* Fold most-significant-first digits in base 2 through 36 into i64. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t any_base_to_decimal(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > 65) return -1;
    const std::int64_t base = input[0];
    if (base < 2 || base > 36) return -1;
    std::int64_t value = 0;
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t digit = input[index];
        if (digit < 0 || digit >= base) return -1;
        if (value > (INT64_MAX - digit) / base) return -1;
        value = value * base + digit;
    }
    return value;
}
