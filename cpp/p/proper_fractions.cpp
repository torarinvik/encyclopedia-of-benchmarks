// Emit reduced proper fractions for one positive denominator.
#include <cstddef>
#include <cstdint>

namespace {
std::uint64_t gcd_u64(std::uint64_t left, std::uint64_t right) {
    while (right != 0) { const auto remainder = left % right; left = right; right = remainder; }
    return left;
}

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
}

extern "C" std::int64_t proper_fractions(const std::int64_t *values, std::size_t length,
                                           std::uint8_t *output,
                                           std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 1) return -1;
    const std::int64_t denominator = values[0];
    if (denominator < 0 || denominator > 256) return -1;
    if (denominator <= 1) return 0;
    std::size_t needed = 0;
    for (std::uint64_t numerator = 1; numerator < static_cast<std::uint64_t>(denominator); ++numerator)
        if (gcd_u64(numerator, static_cast<std::uint64_t>(denominator)) == 1)
            needed += decimal_width(numerator) + decimal_width(static_cast<std::uint64_t>(denominator)) + 2;
    if (output == nullptr || output_capacity < needed) return -2;
    std::size_t position = 0;
    for (std::uint64_t numerator = 1; numerator < static_cast<std::uint64_t>(denominator); ++numerator) {
        if (gcd_u64(numerator, static_cast<std::uint64_t>(denominator)) != 1) continue;
        position = append_decimal(output, position, numerator);
        output[position++] = '/';
        position = append_decimal(output, position, static_cast<std::uint64_t>(denominator));
        output[position++] = '\n';
    }
    return static_cast<std::int64_t>(position);
}
