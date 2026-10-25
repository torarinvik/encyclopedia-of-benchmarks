#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_rows = 8, max_cols = 8;
constexpr std::size_t max_input_length = 2 + 2 * max_rows * max_cols;
constexpr std::size_t bytes_per_value = 8;

void store_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t tsvc_s343_column_major_compaction(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const std::int64_t rows_raw = input[0], cols_raw = input[1];
    if (rows_raw < 1 || rows_raw > static_cast<std::int64_t>(max_rows) ||
        cols_raw < 1 || cols_raw > static_cast<std::int64_t>(max_cols)) return -1;
    const std::size_t rows = static_cast<std::size_t>(rows_raw);
    const std::size_t cols = static_cast<std::size_t>(cols_raw);
    const std::size_t cells = rows * cols;
    if (length != 2 + 2 * cells) return -1;
    if (output == nullptr || output_capacity < cells * bytes_per_value) return -2;

    const std::size_t data_start = 2, mask_start = data_start + cells;
    std::size_t written = 0;
    for (std::size_t col = 0; col < cols; ++col) {
        for (std::size_t row = 0; row < rows; ++row) {
            const std::size_t index = row * cols + col;
            if (input[mask_start + index] > 0) {
                store_i64_le(output, written * bytes_per_value, input[data_start + index]);
                ++written;
            }
        }
    }
    return static_cast<std::int64_t>(written);
}
