/* Convert most-significant-first hexadecimal digits to a signed 64-bit value. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hexadecimal_to_decimal(const std::int64_t *digits,
                                          std::size_t length) noexcept
{
    if (length == 0 || length > 16) return -1;
    if (length == 16 && digits[0] > 7) return -1;
    std::int64_t result = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (digits[index] < 0 || digits[index] > 15) return -1;
        result = result * 16 + digits[index];
    }
    return result;
}
