#include <cstddef>
#include <cstdint>

extern "C" std::int64_t validate_sudoku_board(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 81) return -1;
    for (std::size_t i = 0; i < 81; ++i)
        if (input[i] != '.' && (input[i] < '1' || input[i] > '9')) return -1;
    if (output == nullptr || capacity < 1) return -2;
    std::uint16_t rows[9]{}, columns[9]{}, boxes[9]{};
    bool valid = true;
    for (std::size_t i = 0; i < 81; ++i) {
        if (input[i] == '.') continue;
        const std::size_t row = i / 9, col = i % 9, box = (row / 3) * 3 + col / 3;
        const auto bit = static_cast<std::uint16_t>(1u << (input[i] - '0'));
        if ((rows[row] & bit) || (columns[col] & bit) || (boxes[box] & bit)) valid = false;
        rows[row] |= bit; columns[col] |= bit; boxes[box] |= bit;
    }
    output[0] = static_cast<std::uint8_t>(valid);
    return 1;
}
