// Encode phi(1) through phi(n) as comma-separated decimal bytes.
#include <cstddef>
#include <cstdint>

static std::size_t decimal_length(std::int64_t value)
{
    std::size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static std::size_t append_decimal(std::int64_t value, std::uint8_t *output, std::size_t position)
{
    std::uint8_t digits[3];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>(value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = static_cast<std::uint8_t>('0' + digits[--count]);
    return position;
}

extern "C" std::int64_t compute_totient(std::int64_t n, std::uint8_t *output,
                                         std::size_t output_capacity) noexcept
{
    if (n < 1 || n > 80) return -1;
    std::int64_t phi[80];
    for (std::int64_t i = 1; i <= n; ++i) phi[i - 1] = i;
    for (std::int64_t p = 2; p <= n; ++p) {
        if (phi[p - 1] != p) continue;
        phi[p - 1] = p - 1;
        for (std::int64_t i = 2 * p; i <= n; i += p)
            phi[i - 1] = (phi[i - 1] / p) * (p - 1);
    }
    std::size_t required = static_cast<std::size_t>(n - 1);
    for (std::int64_t i = 0; i < n; ++i) required += decimal_length(phi[i]);
    if (output == nullptr || output_capacity < required) return -2;
    std::size_t position = 0;
    for (std::int64_t i = 0; i < n; ++i) {
        if (i != 0) output[position++] = ',';
        position = append_decimal(phi[i], output, position);
    }
    return static_cast<std::int64_t>(position);
}
