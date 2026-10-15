/* Add reverse-order decimal digit lists with a carry propagated per node. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_digits = 1024; }

extern "C" std::int64_t add_two_numbers(const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 2 + 2 * max_digits) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_digits) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_digits)) return -1;
    const auto first_length = static_cast<std::size_t>(input[0]);
    const auto second_length = static_cast<std::size_t>(input[1]);
    if (length != first_length + second_length + 2) return -1;
    for (std::size_t index = 0; index < first_length + second_length; ++index)
        if (input[index + 2] < 0 || input[index + 2] > 9) return -1;

    const auto digit_count = first_length > second_length ? first_length : second_length;
    std::uint8_t digits[max_digits + 1];
    std::size_t result_length = 0;
    std::int64_t carry = 0;
    for (std::size_t index = 0; index < digit_count || carry != 0; ++index) {
        const auto first = index < first_length ? input[index + 2] : 0;
        const auto second = index < second_length ? input[index + 2 + first_length] : 0;
        const auto sum = first + second + carry;
        digits[result_length++] = static_cast<std::uint8_t>(sum % 10);
        carry = sum / 10;
    }
    if (output_capacity < result_length || (result_length != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < result_length; ++index) output[index] = digits[index];
    return static_cast<std::int64_t>(result_length);
}
