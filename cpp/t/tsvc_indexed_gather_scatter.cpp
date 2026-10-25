#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 16;
constexpr std::size_t max_input_length = 2 + 5 * max_n;
constexpr std::int64_t max_operand = 1000000;

bool bounded_operand(std::int64_t value) {
    return value >= -max_operand && value <= max_operand;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_indexed_gather_scatter(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 6 || length > max_input_length) return -1;
    const std::int64_t mode = input[0], n_raw = input[1];
    if ((mode != 491 && mode != 4113) || n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 2 + (mode == 491 ? 5 : 4) * n) return -1;

    const std::size_t index_start = 2, a_start = index_start + n;
    const std::size_t b_start = a_start + n, c_start = b_start + n, d_start = c_start + n;
    std::int64_t state[max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t index = input[index_start + i];
        if (index < 0 || index >= n_raw) return -1;
        state[i] = input[a_start + i];
        if (!bounded_operand(input[b_start + i]) || !bounded_operand(input[c_start + i])) return -1;
        if (mode == 491 && !bounded_operand(input[d_start + i])) return -1;
    }
    if (output == nullptr || output_capacity < 8 * n) return -2;

    for (std::size_t i = 0; i < n; ++i) {
        const std::size_t index = static_cast<std::size_t>(input[index_start + i]);
        if (mode == 491)
            state[index] = input[b_start + i] + input[c_start + i] * input[d_start + i];
        else
            state[index] = input[b_start + index] + input[c_start + i];
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, state[i]);
    return static_cast<std::int64_t>(n);
}
