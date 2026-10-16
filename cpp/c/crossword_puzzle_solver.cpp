#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cells = 64;
constexpr std::size_t max_words = 8;
constexpr std::size_t max_word_length = 8;

bool search(std::int64_t *grid, std::size_t rows, std::size_t cols,
            const std::int64_t words[max_words][max_word_length],
            const std::size_t lengths[max_words], const std::size_t order[max_words],
            std::size_t depth, std::size_t word_count) {
    if (depth == word_count) return true;
    const std::size_t word_index = order[depth], word_length = lengths[word_index];
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t col = 0; col < cols; ++col) {
            for (int direction = 0; direction < 2; ++direction) {
                const bool vertical = direction == 0;
                if ((vertical && row + word_length > rows) ||
                    (!vertical && col + word_length > cols)) continue;
                std::size_t cells[max_word_length];
                bool newly_filled[max_word_length];
                bool valid = true;
                for (std::size_t i = 0; i < word_length; ++i) {
                    cells[i] = vertical ? (row + i) * cols + col : row * cols + col + i;
                    if (grid[cells[i]] != 0 && grid[cells[i]] != words[word_index][i]) valid = false;
                }
                if (!valid) continue;
                for (std::size_t i = 0; i < word_length; ++i) {
                    newly_filled[i] = grid[cells[i]] == 0;
                    grid[cells[i]] = words[word_index][i];
                }
                if (search(grid, rows, cols, words, lengths, order, depth + 1, word_count)) return true;
                for (std::size_t i = 0; i < word_length; ++i) if (newly_filled[i]) grid[cells[i]] = 0;
            }
        }
    }
    return false;
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t crossword_puzzle_solver(const std::int64_t *input, std::size_t length,
                                                  std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3) return -1;
    const auto rows_value = input[0], cols_value = input[1], count_value = input[2];
    if (rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8 || count_value < 0 || count_value > 8) return -1;
    const auto rows = static_cast<std::size_t>(rows_value), cols = static_cast<std::size_t>(cols_value), word_count = static_cast<std::size_t>(count_value);
    if (length < 3 + rows * cols) return -1;
    std::int64_t grid[max_cells] = {};
    for (std::size_t i = 0; i < rows * cols; ++i) {
        const auto value = input[3 + i];
        if (value != 0 && value != -1 && (value < 65 || value > 90)) return -1;
        grid[i] = value;
    }
    std::int64_t words[max_words][max_word_length] = {};
    std::size_t lengths[max_words] = {}, position = 3 + rows * cols;
    for (std::size_t w = 0; w < word_count; ++w) {
        if (position >= length || input[position] < 1 || input[position] > static_cast<std::int64_t>(max_word_length)) return -1;
        lengths[w] = static_cast<std::size_t>(input[position++]);
        if (lengths[w] > length - position) return -1;
        for (std::size_t i = 0; i < lengths[w]; ++i) {
            const auto letter = input[position++];
            if (letter < 65 || letter > 90) return -1;
            words[w][i] = letter;
        }
    }
    if (position != length) return -1;
    std::size_t order[max_words] = {};
    for (std::size_t i = 0; i < word_count; ++i) order[i] = i;
    for (std::size_t i = 1; i < word_count; ++i) {
        const auto value = order[i];
        std::size_t j = i;
        while (j > 0 && lengths[order[j - 1]] < lengths[value]) { order[j] = order[j - 1]; --j; }
        order[j] = value;
    }
    const bool solved = search(grid, rows, cols, words, lengths, order, 0, word_count);
    const std::size_t required = (1 + rows * cols) * 8;
    if (output == nullptr || capacity < required) return -2;
    put_i64(output, 0, solved ? 1 : 0);
    for (std::size_t i = 0; i < rows * cols; ++i) put_i64(output, (i + 1) * 8, grid[i]);
    return static_cast<std::int64_t>(required);
}
