#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_digits = 64;
constexpr std::size_t max_input_length = 2 + 2 * max_digits;
constexpr std::size_t max_parseable_input_length = max_input_length + 1;
constexpr std::size_t max_output_bytes = max_digits + 1;

bool is_decimal_digit(std::int64_t value) noexcept
{
    return value >= 48 && value <= 57;
}
} // namespace

extern "C" std::int64_t large_number_add(const std::int64_t* input,
                                          std::size_t input_length,
                                          std::uint8_t* output,
                                          std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 2 ||
        input_length > max_parseable_input_length) return -1;

    const std::int64_t left_length_value = input[0];
    const std::int64_t right_length_value = input[1];
    if (left_length_value < 1 || left_length_value > static_cast<std::int64_t>(max_digits) ||
        right_length_value < 1 || right_length_value > static_cast<std::int64_t>(max_digits)) return -1;

    const std::size_t left_length = static_cast<std::size_t>(left_length_value);
    const std::size_t right_length = static_cast<std::size_t>(right_length_value);
    if (input_length != 2 + left_length + right_length) return -1;

    const std::size_t left_start = 2;
    const std::size_t right_start = left_start + left_length;
    for (std::size_t i = 0; i < left_length; ++i) {
        if (!is_decimal_digit(input[left_start + i])) return -1;
    }
    for (std::size_t i = 0; i < right_length; ++i) {
        if (!is_decimal_digit(input[right_start + i])) return -1;
    }
    if ((left_length > 1 && input[left_start] == 48) ||
        (right_length > 1 && input[right_start] == 48)) return -1;

    std::uint8_t reversed[max_output_bytes];
    std::size_t result_length = 0;
    std::size_t index = 0;
    const std::size_t max_length = left_length > right_length ? left_length : right_length;
    std::int64_t carry = 0;
    while (index < max_length || carry != 0) {
        std::int64_t total = carry;
        if (index < right_length) {
            total += input[right_start + right_length - index - 1] - 48;
        }
        if (index < left_length) {
            total += input[left_start + left_length - index - 1] - 48;
        }
        reversed[result_length++] = static_cast<std::uint8_t>(48 + total % 10);
        carry = total / 10;
        ++index;
    }

    std::uint8_t result[max_output_bytes];
    for (std::size_t i = 0; i < result_length; ++i) {
        result[i] = reversed[result_length - i - 1];
    }

    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(result_length);
}
