/* Check full rows, columns, and diagonals for one square-board player. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t n_in_a_row_board_status(const std::int64_t *values,
                                                  std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 258
        || values[0] < 2 || values[0] > 16 || (values[1] != 1 && values[1] != 2)) return -1;
    const auto size = static_cast<std::size_t>(values[0]);
    if (length != 2 + size * size) return -1;
    const auto player = values[1];
    for (std::size_t index = 0; index < size * size; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 2) return -1;

    bool has_empty = false;
    for (std::size_t row = 0; row < size; ++row) {
        bool row_win = true;
        for (std::size_t column = 0; column < size; ++column) {
            const auto cell = values[2 + row * size + column];
            if (cell == 0) has_empty = true;
            if (cell != player) row_win = false;
        }
        if (row_win) return 1;
    }
    for (std::size_t column = 0; column < size; ++column) {
        bool column_win = true;
        for (std::size_t row = 0; row < size; ++row)
            if (values[2 + row * size + column] != player) column_win = false;
        if (column_win) return 1;
    }
    bool main_diagonal_win = true;
    bool anti_diagonal_win = true;
    for (std::size_t index = 0; index < size; ++index) {
        if (values[2 + index * size + index] != player) main_diagonal_win = false;
        if (values[2 + index * size + size - 1 - index] != player) anti_diagonal_win = false;
    }
    if (main_diagonal_win || anti_diagonal_win) return 1;
    return has_empty ? 0 : 2;
}
