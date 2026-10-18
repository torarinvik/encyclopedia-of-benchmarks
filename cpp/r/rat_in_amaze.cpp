#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 4;
constexpr std::size_t max_cells = max_dimension * max_dimension;
constexpr std::size_t max_paths = 184;
constexpr std::size_t max_path_length = max_cells - 1;
constexpr std::size_t max_parseable_input_length = 19;
constexpr std::size_t max_output_words = 2097;
constexpr std::size_t max_output_bytes = max_output_words * 8;
constexpr int java_variant = 0;
constexpr int javascript_variant = 1;
constexpr int moves[2][4][3] = {
    {{1, 0, 0}, {0, -1, 1}, {0, 1, 2}, {-1, 0, 3}},
    {{0, 1, 2}, {1, 0, 0}, {-1, 0, 3}, {0, -1, 1}}
};

struct Maze {
    int variant{};
    std::size_t size{};
    std::array<std::int64_t, max_cells> cells{};
};

struct Paths {
    std::array<std::array<std::uint8_t, max_path_length>, max_paths> directions{};
    std::array<std::size_t, max_paths> lengths{};
    std::size_t count{};
};

bool parse_maze(const std::int64_t *values, std::size_t length, Maze &maze) noexcept
{
    if (values == nullptr || length < 1 || length > max_parseable_input_length) return false;
    if (values[0] != java_variant && values[0] != javascript_variant) return false;
    if (length < 2 || values[1] < 1 || values[1] > static_cast<std::int64_t>(max_dimension)) return false;
    const auto size = static_cast<std::size_t>(values[1]);
    const auto cell_count = size * size;
    if (length != 2 + cell_count) return false;

    maze.variant = static_cast<int>(values[0]);
    maze.size = size;
    for (std::size_t index = 0; index < cell_count; ++index) {
        const auto cell = values[2 + index];
        if (cell != 0 && cell != 1) return false;
        maze.cells[index] = cell;
    }
    return true;
}

bool collect_paths(const Maze &maze, int row, int col,
                   std::array<std::uint8_t, max_cells> &visited,
                   std::array<std::uint8_t, max_path_length> &current,
                   std::size_t path_length, Paths &paths) noexcept
{
    if (row == static_cast<int>(maze.size) - 1 && col == static_cast<int>(maze.size) - 1) {
        const auto slot = paths.count++;
        paths.lengths[slot] = path_length;
        for (std::size_t index = 0; index < path_length; ++index)
            paths.directions[slot][index] = current[index];
        return maze.variant == javascript_variant;
    }

    const auto index = static_cast<std::size_t>(row) * maze.size + static_cast<std::size_t>(col);
    visited[index] = 1;
    for (std::size_t movement = 0; movement < 4; ++movement) {
        const int next_row = row + moves[maze.variant][movement][0];
        const int next_col = col + moves[maze.variant][movement][1];
        if (next_row < 0 || next_col < 0 || next_row >= static_cast<int>(maze.size) ||
            next_col >= static_cast<int>(maze.size)) continue;
        const auto next_index = static_cast<std::size_t>(next_row) * maze.size + static_cast<std::size_t>(next_col);
        if (maze.cells[next_index] != 1 || visited[next_index] != 0) continue;
        current[path_length] = static_cast<std::uint8_t>(moves[maze.variant][movement][2]);
        if (collect_paths(maze, next_row, next_col, visited, current, path_length + 1, paths)) {
            visited[index] = 0;
            return true;
        }
    }
    visited[index] = 0;
    return false;
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

extern "C" std::int64_t rat_in_amaze(const std::int64_t *values, std::size_t length,
                                     std::uint8_t *output, std::size_t output_capacity) noexcept
{
    Maze maze{};
    if (!parse_maze(values, length, maze)) return -1;

    Paths paths{};
    if (maze.cells[0] == 1 && maze.cells[maze.size * maze.size - 1] == 1) {
        std::array<std::uint8_t, max_cells> visited{};
        std::array<std::uint8_t, max_path_length> current{};
        collect_paths(maze, 0, 0, visited, current, 0, paths);
    }
    if (paths.count == 0) return -3;

    std::size_t output_words = 1;
    for (std::size_t path = 0; path < paths.count; ++path) output_words += 1 + paths.lengths[path];
    const auto output_bytes = output_words * 8;
    if (output_bytes > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    std::size_t offset = 0;
    write_i64_le(output, offset, static_cast<std::int64_t>(paths.count));
    offset += 8;
    for (std::size_t path = 0; path < paths.count; ++path) {
        write_i64_le(output, offset, static_cast<std::int64_t>(paths.lengths[path]));
        offset += 8;
        for (std::size_t move = 0; move < paths.lengths[path]; ++move) {
            write_i64_le(output, offset, static_cast<std::int64_t>(paths.directions[path][move]));
            offset += 8;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
