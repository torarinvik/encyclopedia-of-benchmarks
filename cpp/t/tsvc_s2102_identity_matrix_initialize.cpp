// Clean-room bounded profile of TSVC s2102; see package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 8;
constexpr std::size_t max_passes = 8;
constexpr std::size_t max_cells = max_side * max_side;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s2102_identity_matrix_initialize(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length != 2) return -1;
    const std::int64_t side_raw = input[0], passes_raw = input[1];
    if (side_raw < 1 || side_raw > static_cast<std::int64_t>(max_side) ||
        passes_raw < 1 || passes_raw > static_cast<std::int64_t>(max_passes)) return -1;
    const std::size_t side = static_cast<std::size_t>(side_raw), cells = side * side;
    if (output == nullptr || output_capacity < 8 * cells) return -2;

    std::int64_t matrix[max_cells]{};
    for (std::size_t pass = 0; pass < static_cast<std::size_t>(passes_raw); ++pass) {
        for (std::size_t col = 0; col < side; ++col) {
            for (std::size_t row = 0; row < side; ++row) matrix[row * side + col] = 0;
            matrix[col * side + col] = 1;
        }
    }
    for (std::size_t cell = 0; cell < cells; ++cell) store_i64_le(output, 8 * cell, matrix[cell]);
    return static_cast<std::int64_t>(cells);
}
