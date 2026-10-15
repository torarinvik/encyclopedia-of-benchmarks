/* Recursive four-neighbor DFS with a visited set and backtracking. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cells = 36;
constexpr std::size_t max_word_length = 15;

bool is_letter(std::int64_t value) noexcept
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

bool visit(const std::int64_t *input, std::size_t columns, std::size_t cells,
           std::size_t word_start, std::size_t word_length, std::size_t position,
           std::size_t word_index, std::array<bool, max_cells> &visited) noexcept
{
    if (visited[position] || input[2 + position] != input[word_start + word_index]) return false;
    visited[position] = true;
    if (word_index + 1 == word_length) {
        visited[position] = false;
        return true;
    }
    const auto row = position / columns;
    const auto column = position % columns;
    bool found = (row > 0 && visit(input, columns, cells, word_start, word_length,
                                   position - columns, word_index + 1, visited)) ||
                 (row + 1 < cells / columns && visit(input, columns, cells, word_start,
                                    word_length, position + columns, word_index + 1, visited)) ||
                 (column > 0 && visit(input, columns, cells, word_start, word_length,
                                      position - 1, word_index + 1, visited)) ||
                 (column + 1 < columns && visit(input, columns, cells, word_start,
                                    word_length, position + 1, word_index + 1, visited));
    visited[position] = false;
    return found;
}
}

extern "C" std::int64_t word_search(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 5 || input[0] < 1 || input[0] > 6 || input[1] < 1 || input[1] > 6)
        return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    const auto cells = rows * columns;
    const auto word_length_index = 2 + cells;
    if (length <= word_length_index) return -1;
    const auto word_length_value = input[word_length_index];
    if (word_length_value < 1 || word_length_value > static_cast<std::int64_t>(max_word_length) ||
        length != word_length_index + 1 + static_cast<std::size_t>(word_length_value)) return -1;
    const auto word_length = static_cast<std::size_t>(word_length_value);
    for (std::size_t index = 0; index < cells; ++index)
        if (!is_letter(input[2 + index])) return -1;
    const auto word_start = word_length_index + 1;
    for (std::size_t index = 0; index < word_length; ++index)
        if (!is_letter(input[word_start + index])) return -1;
    if (word_length > cells) return 0;
    std::array<bool, max_cells> visited{};
    for (std::size_t position = 0; position < cells; ++position)
        if (visit(input, columns, cells, word_start, word_length, position, 0, visited)) return 1;
    return 0;
}
