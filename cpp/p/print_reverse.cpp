#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 256;
constexpr std::size_t max_parseable_input_length = max_values + 2;
constexpr std::size_t max_output_bytes = 3836;
constexpr std::int64_t i32_min_value = -INT64_C(2147483647) - 1;
constexpr std::int64_t i32_max_value = INT64_C(2147483647);

void append_decimal(std::uint8_t *buffer, std::size_t &position, std::int64_t value)
{
    std::uint8_t digits[10];
    std::size_t count = 0;
    std::uint64_t magnitude;
    if (value < 0) {
        buffer[position++] = static_cast<std::uint8_t>('-');
        magnitude = static_cast<std::uint64_t>(-value);
    } else {
        magnitude = static_cast<std::uint64_t>(value);
    }
    do {
        digits[count++] = static_cast<std::uint8_t>('0' + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    while (count > 0) buffer[position++] = digits[--count];
}
}

extern "C" std::int64_t print_reverse(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity)
{
    if (length > max_parseable_input_length || length > max_values) return -1;
    if (length > 0 && values == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < i32_min_value || values[index] > i32_max_value) return -1;

    std::uint8_t encoded[max_output_bytes];
    std::size_t written = 0;
    for (std::size_t remaining = length; remaining > 0; --remaining) {
        if (written != 0) {
            encoded[written++] = ' ';
            encoded[written++] = '<';
            encoded[written++] = '-';
            encoded[written++] = ' ';
        }
        append_decimal(encoded, written, values[remaining - 1]);
    }

    if (output == nullptr || output_capacity < written) return -2;
    for (std::size_t index = 0; index < written; ++index) output[index] = encoded[index];
    return static_cast<std::int64_t>(written);
}
