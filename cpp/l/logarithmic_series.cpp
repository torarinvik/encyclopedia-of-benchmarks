// Emit the pinned default logarithmic-series expressions as ASCII lines.
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

bool has_negative_sign(std::int64_t delta, std::int64_t term) {
    return delta < 0 ? term % 2 == 1 : term % 2 == 0;
}
}

extern "C" std::int64_t logarithmic_series(const std::int64_t *values, std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t x_value = values[0], n_terms = values[1];
    if (x_value < -10 || x_value > 10 || n_terms < -64 || n_terms > 256) return -1;
    if (n_terms <= 0) return 0;
    const std::int64_t delta = x_value - 1;
    const std::uint64_t base = static_cast<std::uint64_t>(delta < 0 ? -delta : delta);
    std::size_t needed = 0;
    for (std::int64_t term = 1; term <= n_terms; ++term)
        needed += (has_negative_sign(delta, term) ? 2 : 1) + decimal_width(base)
                  + 2 * decimal_width(static_cast<std::uint64_t>(term)) + 4;
    if (output == nullptr || output_capacity < needed) return -2;
    std::size_t position = 0;
    for (std::int64_t term = 1; term <= n_terms; ++term) {
        if (has_negative_sign(delta, term)) output[position++] = '-';
        output[position++] = '(';
        position = append_decimal(output, position, base);
        output[position++] = '^';
        position = append_decimal(output, position, static_cast<std::uint64_t>(term));
        output[position++] = ')'; output[position++] = '/';
        position = append_decimal(output, position, static_cast<std::uint64_t>(term));
        output[position++] = '\n';
    }
    return static_cast<std::int64_t>(position);
}
