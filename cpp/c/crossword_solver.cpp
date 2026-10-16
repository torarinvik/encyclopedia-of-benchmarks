#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_cells = 64;
constexpr std::size_t max_words = 8;
constexpr std::size_t max_word_length = 8;

bool search(std::int64_t *grid, std::size_t rows, std::size_t cols,
            const std::int64_t words[max_words][max_word_length], const std::size_t lengths[max_words],
            std::size_t *remaining, std::size_t remaining_count) {
    std::size_t start = 0;
    while (start < rows * cols && grid[start] != 0) ++start;
    if (start == rows * cols) return true;
    const std::size_t row = start / cols, col = start % cols;
    std::size_t current[max_words], current_count = remaining_count;
    for (std::size_t i = 0; i < remaining_count; ++i) current[i] = remaining[i];
    for (std::size_t wi = 0; wi < remaining_count; ++wi) {
        const std::size_t word_index = remaining[wi], length = lengths[word_index];
        for (int direction = 0; direction < 2; ++direction) {
            const bool vertical = direction == 0;
            if ((vertical && row + length > rows) || (!vertical && col + length > cols)) continue;
            bool valid = true;
            for (std::size_t i = 0; i < length; ++i) {
                const std::size_t cell = vertical ? (row + i) * cols + col : row * cols + col + i;
                if (grid[cell] != 0) { valid = false; break; }
            }
            if (!valid) continue;
            for (std::size_t i = 0; i < length; ++i) {
                const std::size_t cell = vertical ? (row + i) * cols + col : row * cols + col + i;
                grid[cell] = words[word_index][i];
            }
            std::size_t next[max_words], next_count = 0;
            for (std::size_t i = 0; i < current_count; ++i) if (current[i] != word_index) next[next_count++] = current[i];
            std::size_t removed = 0;
            while (removed < current_count && current[removed] != word_index) ++removed;
            for (std::size_t i = removed + 1; i < current_count; ++i) current[i - 1] = current[i];
            --current_count;
            if (search(grid, rows, cols, words, lengths, next, next_count)) return true;
            for (std::size_t i = 0; i < length; ++i) {
                const std::size_t cell = vertical ? (row + i) * cols + col : row * cols + col + i;
                grid[cell] = 0;
            }
            current[current_count++] = word_index;
        }
    }
    return false;
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t crossword_solver(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3) return -1;
    const auto rows_v = input[0], cols_v = input[1], count_v = input[2];
    if (rows_v < 1 || rows_v > 8 || cols_v < 1 || cols_v > 8 || count_v < 0 || count_v > 8) return -1;
    const auto rows = static_cast<std::size_t>(rows_v), cols = static_cast<std::size_t>(cols_v), count = static_cast<std::size_t>(count_v);
    if (length < 3 + rows * cols) return -1;
    std::int64_t grid[max_cells] = {};
    for (std::size_t i = 0; i < rows * cols; ++i) {
        const auto value = input[3 + i];
        if (value != 0 && value != -1 && (value < 65 || value > 90)) return -1;
        grid[i] = value;
    }
    std::int64_t words[max_words][max_word_length] = {};
    std::size_t lengths[max_words] = {}, position = 3 + rows * cols;
    for (std::size_t w = 0; w < count; ++w) {
        if (position >= length || input[position] < 1 || input[position] > 8) return -1;
        lengths[w] = static_cast<std::size_t>(input[position++]);
        if (lengths[w] > length - position) return -1;
        for (std::size_t i = 0; i < lengths[w]; ++i) {
            if (input[position] < 65 || input[position] > 90) return -1;
            words[w][i] = input[position++];
        }
        for (std::size_t prior = 0; prior < w; ++prior) {
            bool equal = lengths[prior] == lengths[w];
            for (std::size_t i = 0; equal && i < lengths[w]; ++i) equal = words[prior][i] == words[w][i];
            if (equal) return -1;
        }
    }
    if (position != length) return -1;
    std::size_t remaining[max_words];
    for (std::size_t i = 0; i < count; ++i) remaining[i] = i;
    const bool solved = search(grid, rows, cols, words, lengths, remaining, count);
    const std::size_t used = 1 + rows * cols, required = used * 8;
    if (output == nullptr || capacity < required) return -2;
    put_i64(output, 0, solved ? 1 : 0);
    for (std::size_t i = 0; i < rows * cols; ++i) put_i64(output, (i + 1) * 8, grid[i]);
    return static_cast<std::int64_t>(required);
}
