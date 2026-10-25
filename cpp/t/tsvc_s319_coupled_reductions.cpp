#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 1 + 3 * max_n;
constexpr std::int64_t max_value = 2;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s319_coupled_reductions(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 1 + 3 * n) return -1;

    const std::size_t c_start = 1, d_start = c_start + n, e_start = d_start + n;
    for (std::size_t i = 0; i < n; ++i) {
        if (input[c_start + i] < -max_value || input[c_start + i] > max_value ||
            input[d_start + i] < -max_value || input[d_start + i] > max_value ||
            input[e_start + i] < -max_value || input[e_start + i] > max_value) return -1;
    }
    const std::size_t value_count = 2 * n + 1;
    if (output == nullptr || output_capacity < 8 * value_count) return -2;

    std::int64_t total = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t a_value = input[c_start + i] + input[d_start + i];
        const std::int64_t b_value = input[c_start + i] + input[e_start + i];
        store_i64_le(output, 8 * i, a_value);
        store_i64_le(output, 8 * (n + i), b_value);
        total += a_value;
        total += b_value;
    }
    store_i64_le(output, 8 * (2 * n), total);
    return static_cast<std::int64_t>(value_count);
}
