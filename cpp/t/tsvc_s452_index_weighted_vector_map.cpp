#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 1 + 2 * max_n;
constexpr std::int64_t max_value = 2;

bool bounded_value(std::int64_t value) {
    return value >= -max_value && value <= max_value;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s452_index_weighted_vector_map(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 1 + 2 * n) return -1;

    const std::size_t b_start = 1, c_start = b_start + n;
    for (std::size_t i = 0; i < n; ++i) {
        if (!bounded_value(input[b_start + i]) || !bounded_value(input[c_start + i])) return -1;
    }
    if (output == nullptr || output_capacity < 8 * n) return -2;

    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t index_weight = static_cast<std::int64_t>(i + 1);
        const std::int64_t value = input[b_start + i] + input[c_start + i] * index_weight;
        store_i64_le(output, 8 * i, value);
    }
    return static_cast<std::int64_t>(n);
}
