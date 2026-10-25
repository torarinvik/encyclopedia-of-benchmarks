// Clean-room bounded profile of TSVC s2111; see package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 8;
constexpr std::size_t max_passes = 4;
constexpr std::size_t max_cells = max_side * max_side;
constexpr std::size_t max_input_length = 2 + max_cells;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s2111_wavefront_add_recurrence(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 6 || length > max_input_length) return -1;
    const std::int64_t side_raw = input[0], passes_raw = input[1];
    if (side_raw < 2 || side_raw > static_cast<std::int64_t>(max_side) ||
        passes_raw < 1 || passes_raw > static_cast<std::int64_t>(max_passes)) return -1;
    const std::size_t side = static_cast<std::size_t>(side_raw), cells = side * side;
    if (length != 2 + cells) return -1;

    std::int64_t matrix[max_cells];
    for (std::size_t cell = 0; cell < cells; ++cell) {
        const std::int64_t value = input[2 + cell];
        if (value < -8 || value > 8) return -1;
        matrix[cell] = value;
    }
    if (output == nullptr || output_capacity < 8 * cells) return -2;

    for (std::size_t pass = 0; pass < static_cast<std::size_t>(passes_raw); ++pass) {
        for (std::size_t row = 1; row < side; ++row) {
            for (std::size_t col = 1; col < side; ++col) {
                matrix[row * side + col] = matrix[row * side + col - 1] + matrix[(row - 1) * side + col];
            }
        }
    }
    for (std::size_t cell = 0; cell < cells; ++cell) store_i64_le(output, 8 * cell, matrix[cell]);
    return static_cast<std::int64_t>(cells);
}
