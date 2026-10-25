#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_cells = max_n * max_n;
constexpr std::size_t max_input_length = 1 + 3 * max_cells;
constexpr std::int64_t max_value = 100;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s2101_diagonal_matrix_fma(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    const std::size_t cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (std::size_t i = 0; i < 3 * cells; ++i)
        if (input[i + 1] < -max_value || input[i + 1] > max_value) return -1;
    if (output == nullptr || output_capacity < 8 * cells) return -2;

    for (std::size_t cell = 0; cell < cells; ++cell)
        store_i64_le(output, 8 * cell, input[cell + 1]);
    for (std::size_t i = 0; i < n; ++i) {
        const std::size_t diagonal = i * n + i;
        const std::int64_t value = input[1 + diagonal] +
            input[1 + cells + diagonal] * input[1 + 2 * cells + diagonal];
        store_i64_le(output, 8 * diagonal, value);
    }
    return static_cast<std::int64_t>(cells);
}
