#include <cstddef>
#include <cstdint>

static std::size_t append_decimal(std::uint8_t *out, std::size_t position, std::size_t value) {
    std::uint8_t digits[4]; std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>(value % 10); value /= 10; } while (value != 0);
    while (count > 0) out[position++] = static_cast<std::uint8_t>('0' + digits[--count]);
    return position;
}

extern "C" std::int64_t harmonic_series(std::int64_t n, std::uint8_t *output, std::size_t capacity) {
    if (n < -512 || n > 512) return -1;
    if (n <= 0) return 0;
    std::size_t needed = 2;
    for (std::size_t term = 2; term <= static_cast<std::size_t>(n); ++term) {
        std::size_t value = term, digits = 0;
        do { ++digits; value /= 10; } while (value != 0);
        needed += digits + 3;
    }
    if (output == nullptr || capacity < needed) return -2;
    std::size_t position = 0;
    output[position++] = '1'; output[position++] = '\n';
    for (std::size_t term = 2; term <= static_cast<std::size_t>(n); ++term) {
        output[position++] = '1'; output[position++] = '/';
        position = append_decimal(output, position, term);
        output[position++] = '\n';
    }
    return static_cast<std::int64_t>(position);
}
