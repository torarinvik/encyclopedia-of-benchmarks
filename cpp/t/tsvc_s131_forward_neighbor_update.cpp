#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 2 + 2 * max_n;
constexpr std::int64_t max_value = 1000000;
constexpr std::int64_t max_passes = 32;

bool bounded_value(std::int64_t value) {
    return value >= -max_value && value <= max_value;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s131_forward_neighbor_update(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0], passes = input[1];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n) || passes < 1 || passes > max_passes) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 2 + 2 * n) return -1;

    std::int64_t a[max_n], b[max_n];
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        if (!bounded_value(a[i]) || !bounded_value(b[i])) return -1;
    }
    if (output == nullptr || output_capacity < 8 * n) return -2;

    for (std::int64_t pass = 0; pass < passes; ++pass)
        for (std::size_t i = 0; i + 1 < n; ++i)
            a[i] = a[i + 1] + b[i];
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(n);
}
