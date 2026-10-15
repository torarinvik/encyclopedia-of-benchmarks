// Format a bounded multiplication table as source-faithful ASCII lines.
#include <cstddef>
#include <cstdint>

namespace {
std::size_t decimal_length(std::int64_t value) noexcept {
    std::size_t length = 1;
    if (value < 0) { ++length; value = -value; }
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

std::size_t append_decimal(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    if (value < 0) { output[position++] = '-'; value = -value; }
    std::uint8_t reversed[20];
    std::size_t count = 0;
    do { reversed[count++] = static_cast<std::uint8_t>('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}
}

extern "C" std::int64_t print_multiplication_table(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto number = input[0];
    const auto terms = input[1];
    if (number < -1000000 || number > 1000000 || terms < -20 || terms > 20) return -1;
    std::size_t required = terms > 0 ? static_cast<std::size_t>(terms) - 1 : 0;
    for (std::int64_t multiplier = 1; multiplier <= terms; ++multiplier) {
        const auto product = number * multiplier;
        required += decimal_length(number) + 3 + decimal_length(multiplier) + 3 + decimal_length(product);
    }
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    std::size_t position = 0;
    for (std::int64_t multiplier = 1; multiplier <= terms; ++multiplier) {
        if (multiplier > 1) output[position++] = '\n';
        position = append_decimal(output, position, number);
        output[position++] = ' '; output[position++] = '*'; output[position++] = ' ';
        position = append_decimal(output, position, multiplier);
        output[position++] = ' '; output[position++] = '='; output[position++] = ' ';
        position = append_decimal(output, position, number * multiplier);
    }
    return static_cast<std::int64_t>(position);
}
