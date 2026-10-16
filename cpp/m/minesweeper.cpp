#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_DIM = 32;
std::size_t write_i64(std::uint8_t *out, std::size_t pos, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[pos++] = static_cast<std::uint8_t>(bits >> (8 * i));
    return pos;
}
}

extern "C" std::int64_t minesweeper(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 2 + MAX_DIM * MAX_DIM) return -1;
    const auto rows_value = input[0], cols_value = input[1];
    if (rows_value < 1 || rows_value > static_cast<std::int64_t>(MAX_DIM) || cols_value < 1 || cols_value > static_cast<std::int64_t>(MAX_DIM)) return -1;
    const auto rows = static_cast<std::size_t>(rows_value), cols = static_cast<std::size_t>(cols_value), count = rows * cols;
    if (length != 2 + count) return -1;
    std::uint8_t cells[MAX_DIM * MAX_DIM], neighbors[MAX_DIM * MAX_DIM];
    for (std::size_t i = 0; i < count; ++i) { if (input[2 + i] != 0 && input[2 + i] != 1) return -1; cells[i] = static_cast<std::uint8_t>(input[2 + i]); }
    for (std::size_t row = 0; row < rows; ++row) for (std::size_t col = 0; col < cols; ++col) {
        unsigned mines = 0;
        for (int dr = -1; dr <= 1; ++dr) for (int dc = -1; dc <= 1; ++dc) {
            if (dr == 0 && dc == 0) continue;
            const int nr = static_cast<int>(row) + dr, nc = static_cast<int>(col) + dc;
            if (nr >= 0 && nr < static_cast<int>(rows) && nc >= 0 && nc < static_cast<int>(cols) && cells[static_cast<std::size_t>(nr) * cols + static_cast<std::size_t>(nc)] == 1) ++mines;
        }
        neighbors[row * cols + col] = static_cast<std::uint8_t>(mines);
    }
    const std::size_t needed = 8 + 8 * count;
    if (output == nullptr || capacity < needed) return -2;
    std::size_t written = write_i64(output, 0, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i) written = write_i64(output, written, neighbors[i]);
    return static_cast<std::int64_t>(written);
}
