/* Zhang-Suen binary image thinning with simultaneous phase deletions. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxRows = 32;
constexpr std::int64_t kMaxColumns = 32;
constexpr std::size_t kMaxCells = 1024;
constexpr std::size_t kMaxParseableInputLength = 2 + kMaxCells + 1;

bool thin_phase(std::array<std::uint8_t, kMaxCells> &image,
                std::array<std::uint8_t, kMaxCells> &marked,
                std::size_t rows, std::size_t columns, bool second_phase) noexcept {
    const std::size_t cells = rows * columns;
    marked.fill(0);
    bool changed = false;
    for (std::size_t row = 1; row + 1 < rows; ++row) {
        for (std::size_t column = 1; column + 1 < columns; ++column) {
            const std::size_t index = row * columns + column;
            if (image[index] == 0) continue;
            const std::uint8_t p2 = image[index - columns];
            const std::uint8_t p3 = image[index - columns + 1];
            const std::uint8_t p4 = image[index + 1];
            const std::uint8_t p5 = image[index + columns + 1];
            const std::uint8_t p6 = image[index + columns];
            const std::uint8_t p7 = image[index + columns - 1];
            const std::uint8_t p8 = image[index - 1];
            const std::uint8_t p9 = image[index - columns - 1];
            const std::array<std::uint8_t, 9> ring{p2, p3, p4, p5, p6, p7, p8, p9, p2};
            unsigned black_neighbors = 0;
            unsigned transitions = 0;
            for (std::size_t neighbor = 0; neighbor < 8; ++neighbor) {
                black_neighbors += ring[neighbor];
                transitions += ring[neighbor] == 0 && ring[neighbor + 1] == 1;
            }
            if (black_neighbors < 2 || black_neighbors > 6 || transitions != 1) continue;
            const bool blocked = second_phase
                ? ((p2 && p4 && p8) || (p2 && p6 && p8))
                : ((p2 && p4 && p6) || (p4 && p6 && p8));
            if (blocked) continue;
            marked[index] = 1;
            changed = true;
        }
    }
    if (changed) {
        for (std::size_t index = 0; index < cells; ++index) {
            if (marked[index]) image[index] = 0;
        }
    }
    return changed;
}
} // namespace

extern "C" std::int64_t zhang_suen_thinning(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > kMaxParseableInputLength) return -1;
    const std::int64_t rows_value = input[0];
    const std::int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > kMaxRows ||
        columns_value < 1 || columns_value > kMaxColumns) return -1;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    const std::size_t cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (std::size_t index = 0; index < cells; ++index) {
        if (input[index + 2] != 0 && input[index + 2] != 1) return -1;
    }
    if (output == nullptr || output_capacity < cells) return -2;

    std::array<std::uint8_t, kMaxCells> image{};
    std::array<std::uint8_t, kMaxCells> marked{};
    for (std::size_t index = 0; index < cells; ++index)
        image[index] = static_cast<std::uint8_t>(input[index + 2]);
    for (;;) {
        const bool first_changed = thin_phase(image, marked, rows, columns, false);
        const bool second_changed = thin_phase(image, marked, rows, columns, true);
        if (!first_changed && !second_changed) break;
    }
    for (std::size_t index = 0; index < cells; ++index) output[index] = image[index];
    return static_cast<std::int64_t>(cells);
}
