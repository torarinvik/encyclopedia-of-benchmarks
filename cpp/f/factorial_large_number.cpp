/* Multiply a base-10 digit array by each factor through n. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxN = 100;
constexpr std::size_t kMaxDigits = 160;
}

extern "C" std::int64_t factorial_large_number(std::int64_t n, std::uint8_t *output,
                                                  std::size_t output_capacity) noexcept {
    if (n < 0 || n > kMaxN) return -1;
    std::int64_t digits[kMaxDigits]{};
    digits[0] = 1;
    std::size_t digit_count = 1;
    for (std::int64_t factor = 2; factor <= n; ++factor) {
        std::int64_t carry = 0;
        for (std::size_t i = 0; i < digit_count; ++i) {
            const auto product = digits[i] * factor + carry;
            digits[i] = product % 10;
            carry = product / 10;
        }
        while (carry != 0) {
            digits[digit_count++] = carry % 10;
            carry /= 10;
        }
    }
    if (output == nullptr || output_capacity < digit_count) return -2;
    for (std::size_t i = 0; i < digit_count; ++i)
        output[i] = static_cast<std::uint8_t>('0' + digits[digit_count - i - 1]);
    return static_cast<std::int64_t>(digit_count);
}
