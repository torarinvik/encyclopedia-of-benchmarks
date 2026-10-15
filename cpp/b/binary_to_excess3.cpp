/* Parse an ASCII base-2 integer, add three, and format with minimum width four. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 128;
constexpr std::int64_t max_magnitude = INT64_C(4611686018427387904);

bool is_ascii_space(std::int64_t value)
{
    return value == 32 || (value >= 9 && value <= 13);
}

bool is_binary_digit(std::int64_t value)
{
    return value == '0' || value == '1';
}
}

extern "C" std::int64_t binary_to_excess3(const std::int64_t *values, std::size_t length,
                                           std::uint8_t *output,
                                           std::size_t output_capacity) noexcept
{
    if (values == nullptr || length == 0 || length > max_text_length) return -1;
    std::size_t start = 0, end = length;
    while (start < end && is_ascii_space(values[start])) ++start;
    while (end > start && is_ascii_space(values[end - 1])) --end;
    if (start == end) return -1;

    bool negative = false;
    if (values[start] == '+' || values[start] == '-') {
        negative = values[start] == '-';
        ++start;
        if (start == end) return -1;
    }
    const bool prefixed = end - start >= 2 && values[start] == '0' &&
                          (values[start + 1] == 'b' || values[start + 1] == 'B');
    if (prefixed) start += 2;
    if (start == end) return -1;

    const std::size_t digit_start = start;
    bool allow_prefix_underscore = prefixed;
    bool have_digit = false, last_was_digit = false;
    std::int64_t magnitude = 0;
    for (std::size_t index = start; index < end; ++index) {
        const std::int64_t value = values[index];
        if (is_binary_digit(value)) {
            const std::int64_t digit = value - '0';
            if (magnitude > (max_magnitude - digit) / 2) return -1;
            magnitude = magnitude * 2 + digit;
            have_digit = true;
            last_was_digit = true;
            allow_prefix_underscore = false;
        } else if (value == '_') {
            if (last_was_digit && index + 1 < end && is_binary_digit(values[index + 1])) {
                last_was_digit = false;
            } else if (allow_prefix_underscore && !have_digit && index == digit_start &&
                       index + 1 < end && is_binary_digit(values[index + 1])) {
                allow_prefix_underscore = false;
            } else {
                return -1;
            }
        } else {
            return -1;
        }
    }
    if (!have_digit || !last_was_digit) return -1;

    std::int64_t result = (negative ? -magnitude : magnitude) + 3;
    const bool result_is_negative = result < 0;
    std::int64_t remaining = result_is_negative ? -result : result;
    std::uint8_t reversed[64];
    std::size_t digit_count = 0;
    do {
        reversed[digit_count++] = static_cast<std::uint8_t>('0' + remaining % 2);
        remaining /= 2;
    } while (remaining > 0);

    const std::size_t sign_length = result_is_negative ? 1 : 0;
    std::size_t output_length = sign_length + digit_count;
    if (output_length < 4) output_length = 4;
    if (output == nullptr || output_capacity < output_length) return -2;
    std::size_t position = 0;
    if (result_is_negative) output[position++] = static_cast<std::uint8_t>('-');
    const std::size_t digit_width = output_length - sign_length;
    for (std::size_t pad = digit_count; pad < digit_width; ++pad)
        output[position++] = static_cast<std::uint8_t>('0');
    while (digit_count > 0) output[position++] = reversed[--digit_count];
    return static_cast<std::int64_t>(output_length);
}
