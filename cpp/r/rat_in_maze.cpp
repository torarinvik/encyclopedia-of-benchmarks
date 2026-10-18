#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 8;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr std::size_t max_parseable_input_length = 71;
constexpr std::size_t max_output_bytes = max_cells * 8;
constexpr int python_variant = 0;
constexpr int rust_variant = 1;
constexpr int directions[2][4][2] = {
    {{1, 0}, {0, 1}, {-1, 0}, {0, -1}},
    {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
};

struct Maze {
    int variant{};
    std::size_t rows{};
    std::size_t cols{};
    std::size_t start_row{};
    std::size_t start_col{};
    std::size_t destination_row{};
    std::size_t destination_col{};
    std::array<std::int64_t, max_cells> cells{};
};

bool search_path(const Maze &maze, int row, int col,
                 std::array<std::uint8_t, max_cells> &path) noexcept
{
    if (maze.variant == rust_variant && row == static_cast<int>(maze.destination_row) &&
        col == static_cast<int>(maze.destination_col)) {
        path[static_cast<std::size_t>(row) * maze.cols + static_cast<std::size_t>(col)] = 1;
        return true;
    }
    if (row < 0 || col < 0 || row >= static_cast<int>(maze.rows) || col >= static_cast<int>(maze.cols))
        return false;

    const auto index = static_cast<std::size_t>(row) * maze.cols + static_cast<std::size_t>(col);
    const std::int64_t open_value = maze.variant == python_variant ? 0 : 1;
    if (maze.cells[index] != open_value || path[index] != 0) return false;
    path[index] = 1;
    if (maze.variant == python_variant && row == static_cast<int>(maze.destination_row) &&
        col == static_cast<int>(maze.destination_col)) return true;

    for (std::size_t move = 0; move < 4; ++move) {
        if (search_path(maze, row + directions[maze.variant][move][0],
                        col + directions[maze.variant][move][1], path)) return true;
    }
    path[index] = 0;
    return false;
}

bool parse_maze(const std::int64_t *values, std::size_t length, Maze &maze) noexcept
{
    if (values == nullptr || length < 1 || length > max_parseable_input_length) return false;
    if (values[0] == python_variant) {
        if (length < 7 || values[1] < 1 || values[1] > static_cast<std::int64_t>(max_dimension)) return false;
        const auto size = static_cast<std::size_t>(values[1]);
        if (length != 6 + size * size) return false;
        if (values[2] < 0 || values[2] >= static_cast<std::int64_t>(size) ||
            values[3] < 0 || values[3] >= static_cast<std::int64_t>(size) ||
            values[4] < 0 || values[4] >= static_cast<std::int64_t>(size) ||
            values[5] < 0 || values[5] >= static_cast<std::int64_t>(size)) return false;
        maze.variant = python_variant;
        maze.rows = size;
        maze.cols = size;
        maze.start_row = static_cast<std::size_t>(values[2]);
        maze.start_col = static_cast<std::size_t>(values[3]);
        maze.destination_row = static_cast<std::size_t>(values[4]);
        maze.destination_col = static_cast<std::size_t>(values[5]);
        for (std::size_t index = 0; index < size * size; ++index) {
            const auto cell = values[6 + index];
            if (cell != 0 && cell != 1) return false;
            maze.cells[index] = cell;
        }
    } else if (values[0] == rust_variant) {
        if (length < 6 || values[1] < 1 || values[1] > static_cast<std::int64_t>(max_dimension) ||
            values[2] < 1 || values[2] > static_cast<std::int64_t>(max_dimension)) return false;
        const auto rows = static_cast<std::size_t>(values[1]);
        const auto cols = static_cast<std::size_t>(values[2]);
        if (length != 5 + rows * cols || values[3] < 0 || values[3] >= static_cast<std::int64_t>(rows) ||
            values[4] < 0 || values[4] >= static_cast<std::int64_t>(cols)) return false;
        maze.variant = rust_variant;
        maze.rows = rows;
        maze.cols = cols;
        maze.start_row = static_cast<std::size_t>(values[3]);
        maze.start_col = static_cast<std::size_t>(values[4]);
        maze.destination_row = rows - 1;
        maze.destination_col = cols - 1;
        for (std::size_t index = 0; index < rows * cols; ++index) {
            const auto cell = values[5 + index];
            if (cell != 0 && cell != 1) return false;
            maze.cells[index] = cell;
        }
    } else return false;
    return true;
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t rat_in_maze(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    Maze maze{};
    if (!parse_maze(values, length, maze)) return -1;
    std::array<std::uint8_t, max_cells> path{};
    if (!search_path(maze, static_cast<int>(maze.start_row), static_cast<int>(maze.start_col), path)) return -3;

    const auto cells = maze.rows * maze.cols;
    const auto output_bytes = cells * 8;
    if (output_bytes > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < cells; ++index) {
        const std::int64_t value = maze.variant == python_variant ?
            (path[index] != 0 ? 0 : 1) : (path[index] != 0 ? 1 : 0);
        write_i64_le(output, index * 8, value);
    }
    return static_cast<std::int64_t>(output_bytes);
}
