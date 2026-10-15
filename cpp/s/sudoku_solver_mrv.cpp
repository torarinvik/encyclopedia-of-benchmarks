// Solve Sudoku with constraint propagation and minimum-remaining-values search.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t sudoku_cells = 81;
constexpr std::uint16_t all_digits = 0x03FE;

bool is_single(std::uint16_t candidates) noexcept
{
    return candidates != 0 && (candidates & static_cast<std::uint16_t>(candidates - 1)) == 0;
}

bool assign(std::uint16_t *candidates, std::size_t cell, std::uint16_t selected);

bool eliminate(std::uint16_t *candidates, std::size_t cell, std::uint16_t removed)
{
    if ((candidates[cell] & removed) == 0) return true;
    candidates[cell] = static_cast<std::uint16_t>(candidates[cell] & static_cast<std::uint16_t>(~removed));
    const auto remaining = candidates[cell];
    if (remaining == 0) return false;

    if (is_single(remaining)) {
        for (std::size_t peer = 0; peer < sudoku_cells; ++peer) {
            if (peer == cell) continue;
            const auto row = cell / 9, column = cell % 9;
            const auto peer_row = peer / 9, peer_column = peer % 9;
            const bool shares_row = row == peer_row;
            const bool shares_column = column == peer_column;
            const bool shares_box = row / 3 == peer_row / 3 && column / 3 == peer_column / 3;
            if ((shares_row || shares_column || shares_box) && !eliminate(candidates, peer, remaining))
                return false;
        }
    }

    const auto row = cell / 9, column = cell % 9;
    const auto box_row = row / 3 * 3, box_column = column / 3 * 3;
    for (std::size_t unit = 0; unit < 3; ++unit) {
        std::size_t only_place = 0, place_count = 0;
        for (std::size_t offset = 0; offset < 9; ++offset) {
            std::size_t place;
            if (unit == 0) place = row * 9 + offset;
            else if (unit == 1) place = offset * 9 + column;
            else place = (box_row + offset / 3) * 9 + box_column + offset % 3;
            if ((candidates[place] & removed) != 0) {
                only_place = place;
                ++place_count;
            }
        }
        if (place_count == 0) return false;
        if (place_count == 1 && !assign(candidates, only_place, removed)) return false;
    }
    return true;
}

bool assign(std::uint16_t *candidates, std::size_t cell, std::uint16_t selected)
{
    if ((candidates[cell] & selected) == 0) return false;
    auto other = static_cast<std::uint16_t>(candidates[cell] & static_cast<std::uint16_t>(~selected));
    while (other != 0) {
        const auto bit = static_cast<std::uint16_t>(other & static_cast<std::uint16_t>(0U - other));
        other = static_cast<std::uint16_t>(other & static_cast<std::uint16_t>(~bit));
        if (!eliminate(candidates, cell, bit)) return false;
    }
    return true;
}

bool search(std::uint16_t *candidates)
{
    std::size_t best_cell = sudoku_cells;
    unsigned int best_count = 10;
    for (std::size_t cell = 0; cell < sudoku_cells; ++cell) {
        unsigned int count = 0;
        for (auto bits = candidates[cell]; bits != 0; bits = static_cast<std::uint16_t>(bits & (bits - 1)))
            ++count;
        if (count == 0) return false;
        if (count > 1 && count < best_count) {
            best_cell = cell;
            best_count = count;
        }
    }
    if (best_cell == sudoku_cells) return true;

    const auto choices = candidates[best_cell];
    for (unsigned int digit = 1; digit <= 9; ++digit) {
        const auto bit = static_cast<std::uint16_t>(1U << digit);
        if ((choices & bit) == 0) continue;
        std::uint16_t branch[sudoku_cells];
        for (std::size_t cell = 0; cell < sudoku_cells; ++cell) branch[cell] = candidates[cell];
        if (assign(branch, best_cell, bit) && search(branch)) {
            for (std::size_t cell = 0; cell < sudoku_cells; ++cell) candidates[cell] = branch[cell];
            return true;
        }
    }
    return false;
}
}

extern "C" std::int64_t sudoku_solver_mrv(const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length != sudoku_cells) return -1;
    std::uint16_t candidates[sudoku_cells];
    for (std::size_t cell = 0; cell < sudoku_cells; ++cell) {
        if (values[cell] < 0 || values[cell] > 9) return -1;
        candidates[cell] = all_digits;
    }
    for (std::size_t cell = 0; cell < sudoku_cells; ++cell) {
        if (values[cell] != 0 && !assign(candidates, cell, static_cast<std::uint16_t>(1U << values[cell])))
            return -1;
    }
    if (!search(candidates)) return -1;
    if (output == nullptr || output_capacity < 4 * sudoku_cells) return -2;
    for (std::size_t cell = 0; cell < sudoku_cells; ++cell) {
        unsigned int digit = 1;
        while ((candidates[cell] & (1U << digit)) == 0) ++digit;
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[cell * 4 + byte] = static_cast<std::uint8_t>(digit >> (byte * 8));
    }
    return static_cast<std::int64_t>(sudoku_cells);
}
