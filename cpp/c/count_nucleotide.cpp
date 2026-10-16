// Count A/C/G/T and return all four counts as an ASCII string.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_SEQUENCE_LENGTH = 1000;
std::size_t decimal_length(std::int64_t value) noexcept {
    std::size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}
std::size_t write_decimal(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    std::int64_t divisor = 1;
    while (value / divisor >= 10) divisor *= 10;
    while (divisor > 0) {
        output[offset++] = static_cast<std::uint8_t>('0' + value / divisor);
        value %= divisor;
        divisor /= 10;
    }
    return offset;
}
}

extern "C" std::int64_t count_nucleotide(const std::int64_t *values, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 1 || length > 1001) return -1;
    const auto count_value = values[0];
    if (count_value < 0 || count_value > MAX_SEQUENCE_LENGTH ||
        length != static_cast<std::size_t>(count_value) + 1) return -1;
    std::int64_t count_a = 0, count_c = 0, count_g = 0, count_t = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count_value); ++i) {
        const auto codepoint = values[1 + i];
        if (codepoint < 0 || codepoint > 127) return -1;
        if (codepoint == 65) ++count_a;
        else if (codepoint == 67) ++count_c;
        else if (codepoint == 71) ++count_g;
        else if (codepoint == 84) ++count_t;
    }
    const auto output_length = decimal_length(count_a) + decimal_length(count_c) +
        decimal_length(count_g) + decimal_length(count_t) + 3;
    if (output == nullptr || capacity < output_length) return -2;
    std::size_t offset = write_decimal(output, 0, count_a); output[offset++] = ' ';
    offset = write_decimal(output, offset, count_c); output[offset++] = ' ';
    offset = write_decimal(output, offset, count_g); output[offset++] = ' ';
    offset = write_decimal(output, offset, count_t);
    return static_cast<std::int64_t>(offset);
}
