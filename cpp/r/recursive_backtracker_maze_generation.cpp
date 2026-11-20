#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t recursive_backtracker_maze_generation(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 68) return -1;
    const auto rows_word = input[0], cols_word = input[1];
    const auto start_word = input[2], draws_word = input[3];
    if (rows_word < 1 || rows_word > 64 || cols_word < 1 || cols_word > 64) return -1;
    const auto rows = static_cast<std::size_t>(rows_word);
    const auto cols = static_cast<std::size_t>(cols_word);
    const std::size_t cells = rows * cols;
    if (cells > 64 || start_word < 0 || static_cast<std::uint64_t>(start_word) >= cells ||
        draws_word != static_cast<std::int64_t>(cells - 1) || length != 4 + cells - 1) return -1;
    for (std::size_t draw = 0; draw < cells - 1; ++draw)
        if (input[4 + draw] < 0 || input[4 + draw] > 3) return -1;

    std::array<bool, 64> seen{};
    std::array<std::uint8_t, 64> walls{};
    walls.fill(15);
    std::array<std::size_t, 64> stack{};
    std::size_t stack_size = 1, tape_index = 0;
    stack[0] = static_cast<std::size_t>(start_word);
    seen[stack[0]] = true;
    while (stack_size > 0) {
        const auto cell = stack[stack_size - 1];
        const auto row = cell / cols, col = cell % cols;
        std::array<std::size_t, 4> next_cells{}, directions{};
        std::size_t options = 0;
        if (row > 0 && !seen[cell - cols]) { next_cells[options] = cell - cols; directions[options++] = 0; }
        if (col + 1 < cols && !seen[cell + 1]) { next_cells[options] = cell + 1; directions[options++] = 1; }
        if (row + 1 < rows && !seen[cell + cols]) { next_cells[options] = cell + cols; directions[options++] = 2; }
        if (col > 0 && !seen[cell - 1]) { next_cells[options] = cell - 1; directions[options++] = 3; }
        if (options == 0) { --stack_size; continue; }
        if (tape_index >= cells - 1) return -1;
        const auto choice = static_cast<std::size_t>(input[4 + tape_index++]);
        if (choice >= options) return -1;
        const auto next = next_cells[choice], direction = directions[choice];
        seen[next] = true;
        walls[cell] &= static_cast<std::uint8_t>(~(1u << direction));
        walls[next] &= static_cast<std::uint8_t>(~(1u << ((direction + 2) & 3u)));
        stack[stack_size++] = next;
    }
    if (tape_index != cells - 1) return -1;
    for (std::size_t cell = 0; cell < cells; ++cell) if (!seen[cell]) return -1;
    if (output == nullptr || capacity < cells) return -2;
    for (std::size_t cell = 0; cell < cells; ++cell) output[cell] = walls[cell];
    return static_cast<std::int64_t>(cells);
}
