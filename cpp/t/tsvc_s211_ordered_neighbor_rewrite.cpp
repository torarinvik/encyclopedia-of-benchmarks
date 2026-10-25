#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 2 + 5 * max_n;
constexpr std::int64_t max_value = 2;
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

extern "C" std::int64_t tsvc_s211_ordered_neighbor_rewrite(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 17 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0], passes = input[1];
    if (n_raw < 3 || n_raw > static_cast<std::int64_t>(max_n) || passes < 1 || passes > max_passes) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 2 + 5 * n) return -1;

    const std::size_t a_start = 2, b_start = a_start + n, c_start = b_start + n;
    const std::size_t d_start = c_start + n, e_start = d_start + n;
    std::int64_t a[max_n], b[max_n];
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[a_start + i];
        b[i] = input[b_start + i];
        if (!bounded_value(a[i]) || !bounded_value(b[i]) ||
            !bounded_value(input[c_start + i]) || !bounded_value(input[d_start + i]) ||
            !bounded_value(input[e_start + i])) return -1;
    }
    if (output == nullptr || output_capacity < 16 * n) return -2;

    for (std::int64_t pass = 0; pass < passes; ++pass) {
        for (std::size_t i = 1; i + 1 < n; ++i) {
            a[i] = b[i - 1] + input[c_start + i] * input[d_start + i];
            b[i] = b[i + 1] - input[e_start + i] * input[d_start + i];
        }
    }
    for (std::size_t i = 0; i < n; ++i) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
    }
    return static_cast<std::int64_t>(2 * n);
}
