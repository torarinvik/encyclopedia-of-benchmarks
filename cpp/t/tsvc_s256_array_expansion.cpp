#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 16;
constexpr std::size_t max_cells = max_n * max_n;
constexpr std::size_t max_input_length = 2 + max_n + 2 * max_cells;
constexpr std::int64_t max_a0 = 1'000;
constexpr std::int64_t max_factor = 1'000;
constexpr std::int64_t max_c0 = 1'000'000;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t tsvc_s256_array_expansion(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 5 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0];
    const std::int64_t a0 = input[1];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n) || a0 < -max_a0 || a0 > max_a0) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    const std::size_t cells = n * n;
    if (length != 2 + n + 2 * cells) return -1;
    const std::size_t d_start = 2;
    const std::size_t b_start = d_start + n;
    const std::size_t c_start = b_start + cells;
    for (std::size_t i = 0; i < n; ++i)
        if (input[d_start + i] < -max_factor || input[d_start + i] > max_factor) return -1;
    for (std::size_t i = 0; i < cells; ++i) {
        if (input[b_start + i] < -max_factor || input[b_start + i] > max_factor ||
            input[c_start + i] < -max_c0 || input[c_start + i] > max_c0) return -1;
    }

    const std::size_t output_values = n + cells;
    if (output == nullptr || output_capacity < output_values * 8) return -2;
    std::int64_t a[max_n]{};
    std::int64_t c[max_cells]{};
    a[0] = a0;
    for (std::size_t cell = 0; cell < cells; ++cell) c[cell] = input[c_start + cell];
    for (std::size_t column = 0; column < n; ++column) {
        for (std::size_t row = 1; row < n; ++row) {
            a[row] = 1 - a[row - 1];
            const std::size_t cell = row * n + column;
            c[cell] = a[row] + input[b_start + cell] * input[d_start + row];
        }
    }
    for (std::size_t row = 0; row < n; ++row) store_i64_le(output, row * 8, a[row]);
    for (std::size_t cell = 0; cell < cells; ++cell)
        store_i64_le(output, (n + cell) * 8, c[cell]);
    return static_cast<std::int64_t>(output_values);
}
