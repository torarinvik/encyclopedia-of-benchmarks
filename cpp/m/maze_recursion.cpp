#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t grid_rows = 8;
constexpr std::size_t grid_cols = 7;
constexpr std::size_t grid_cells = grid_rows * grid_cols;
constexpr std::size_t input_words = 1 + grid_cells;
constexpr std::size_t output_bytes = 4 * input_words;
constexpr std::size_t start_index = 1 * grid_cols + 1;
constexpr std::size_t target_index = 6 * grid_cols + 5;

bool solve_maze(std::array<std::uint8_t, grid_cells>& grid, int row, int col, int strategy) {
    if (grid[target_index] == 2) return true;
    const auto index = static_cast<std::size_t>(row * static_cast<int>(grid_cols) + col);
    if (grid[index] != 0) return false;
    grid[index] = 2;

    if (strategy == 0) {
        if (solve_maze(grid, row + 1, col, strategy)) return true;
        if (solve_maze(grid, row, col + 1, strategy)) return true;
        if (solve_maze(grid, row - 1, col, strategy)) return true;
        if (solve_maze(grid, row, col - 1, strategy)) return true;
    } else {
        if (solve_maze(grid, row - 1, col, strategy)) return true;
        if (solve_maze(grid, row, col + 1, strategy)) return true;
        if (solve_maze(grid, row + 1, col, strategy)) return true;
        if (solve_maze(grid, row, col - 1, strategy)) return true;
    }

    grid[index] = 3;
    return false;
}

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t maze_recursion(const std::int64_t* input,
                                        std::size_t length,
                                        std::uint8_t* output,
                                        std::size_t capacity) {
    if (input == nullptr || length != input_words) return -1;
    if (input[0] < 0 || input[0] > 1) return -1;
    const auto strategy = static_cast<int>(input[0]);

    std::array<std::uint8_t, grid_cells> grid{};
    for (std::size_t index = 0; index < grid_cells; ++index) {
        const auto cell = input[index + 1];
        if (cell != 0 && cell != 1) return -1;
        grid[index] = static_cast<std::uint8_t>(cell);
    }
    for (std::size_t row = 0; row < grid_rows; ++row) {
        for (std::size_t col = 0; col < grid_cols; ++col) {
            if ((row == 0 || row == grid_rows - 1 || col == 0 || col == grid_cols - 1) &&
                grid[row * grid_cols + col] != 1) return -1;
        }
    }
    if (grid[start_index] != 0 || grid[target_index] != 0) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;

    const bool found = solve_maze(grid, 1, 1, strategy);
    std::array<std::uint8_t, output_bytes> buffer{};
    put_i32_le(buffer.data(), 0, found ? 1 : 0);
    for (std::size_t index = 0; index < grid_cells; ++index)
        put_i32_le(buffer.data(), 4 * (index + 1), grid[index]);
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(output_bytes);
}
