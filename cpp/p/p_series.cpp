// Emit the bounded Python P-series list as newline-delimited ASCII.
#include <cstddef>
#include <cstdint>

namespace {
std::size_t decimal_width(std::uint64_t value) {
    std::size_t width = 1;
    while (value >= 10) { value /= 10; ++width; }
    return width;
}

std::size_t append_decimal(std::uint8_t *output, std::size_t position, std::uint64_t value) {
    std::uint8_t digits[20];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>(value % 10); value /= 10; } while (value != 0);
    while (count > 0) output[position++] = static_cast<std::uint8_t>('0' + digits[--count]);
    return position;
}

std::uint64_t term_power(std::size_t term, std::int64_t power) {
    std::uint64_t result = 1;
    for (std::int64_t index = 0; index < power; ++index) result *= static_cast<std::uint64_t>(term);
    return result;
}
}

extern "C" std::int64_t p_series(const std::int64_t *values, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t nth_term = values[0], power = values[1];
    if (nth_term < -256 || nth_term > 256 || power < 0 || power > 7) return -1;
    if (nth_term <= 0) return 0;
    std::size_t needed = 2;
    for (std::size_t term = 2; term <= static_cast<std::size_t>(nth_term); ++term)
        needed += 5 + decimal_width(term_power(term, power));
    if (output == nullptr || output_capacity < needed) return -2;
    std::size_t position = 0;
    output[position++] = '1'; output[position++] = '\n';
    for (std::size_t term = 2; term <= static_cast<std::size_t>(nth_term); ++term) {
        output[position++] = '1'; output[position++] = ' ';
        output[position++] = '/'; output[position++] = ' ';
        position = append_decimal(output, position, term_power(term, power));
        output[position++] = '\n';
    }
    return static_cast<std::int64_t>(position);
}
