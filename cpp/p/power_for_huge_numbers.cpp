#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_output_bytes = 513; }

extern "C" std::int64_t power_for_huge_numbers(const std::int64_t *input,
                                                std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t capacity) noexcept {
    if (input == nullptr || length != 2) return -1;
    const std::int64_t base = input[0];
    const std::int64_t exponent = input[1];
    if (base < 1 || base > 10000 || exponent < 0 || exponent > 128) return -1;

    std::uint8_t digits[max_output_bytes] = {1};
    std::size_t digit_count = 1;
    for (std::int64_t power = 0; power < exponent; ++power) {
        std::uint32_t carry = 0;
        for (std::size_t i = 0; i < digit_count; ++i) {
            const std::uint32_t product = static_cast<std::uint32_t>(digits[i]) *
                                          static_cast<std::uint32_t>(base) + carry;
            digits[i] = static_cast<std::uint8_t>(product % 10);
            carry = product / 10;
        }
        while (carry != 0) {
            if (digit_count == max_output_bytes) return -1;
            digits[digit_count++] = static_cast<std::uint8_t>(carry % 10);
            carry /= 10;
        }
    }
    if (output == nullptr || capacity < digit_count) return -2;
    for (std::size_t i = 0; i < digit_count; ++i)
        output[i] = static_cast<std::uint8_t>('0' + digits[digit_count - 1 - i]);
    return static_cast<std::int64_t>(digit_count);
}
