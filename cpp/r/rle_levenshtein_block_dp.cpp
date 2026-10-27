/* Run-length-native unit-cost edit distance by run-pair blocks. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rle_levenshtein_block_dp(const std::int64_t *packed,
                                                   std::size_t length) noexcept {
    if (packed == nullptr || length < 4 || length > 18 || packed[0] < 1 || packed[0] > 4) return -1;
    const std::size_t left_count = static_cast<std::size_t>(packed[0]);
    const std::size_t right_index = 1 + 2 * left_count;
    if (right_index >= length || packed[right_index] < 1 || packed[right_index] > 4) return -1;
    const std::size_t right_count = static_cast<std::size_t>(packed[right_index]);
    if (length != right_index + 1 + 2 * right_count) return -1;
    std::int64_t left_symbol[4], left_size[4], right_symbol[4], right_size[4];
    std::size_t left_total = 0, right_total = 0;
    for (std::size_t run = 0; run < left_count; ++run) {
        left_symbol[run] = packed[1 + 2 * run]; left_size[run] = packed[2 + 2 * run];
        if (left_symbol[run] < 0 || left_symbol[run] > 3 || left_size[run] < 1 || left_size[run] > 8) return -1;
        left_total += static_cast<std::size_t>(left_size[run]); if (left_total > 16) return -1;
    }
    for (std::size_t run = 0; run < right_count; ++run) {
        right_symbol[run] = packed[right_index + 1 + 2 * run]; right_size[run] = packed[right_index + 2 + 2 * run];
        if (right_symbol[run] < 0 || right_symbol[run] > 3 || right_size[run] < 1 || right_size[run] > 8) return -1;
        right_total += static_cast<std::size_t>(right_size[run]); if (right_total > 16) return -1;
    }
    std::int64_t bottom[4][9]{}, next_bottom[4][9]{};
    std::size_t right_prefix = 0;
    for (std::size_t j = 0; j < right_count; ++j) {
        for (std::size_t col = 0; col <= static_cast<std::size_t>(right_size[j]); ++col) bottom[j][col] = static_cast<std::int64_t>(right_prefix + col);
        right_prefix += static_cast<std::size_t>(right_size[j]);
    }
    std::size_t left_prefix = 0;
    for (std::size_t i = 0; i < left_count; ++i) {
        const std::size_t rows = static_cast<std::size_t>(left_size[i]);
        std::int64_t left_boundary[9]{};
        for (std::size_t row = 0; row <= rows; ++row) left_boundary[row] = static_cast<std::int64_t>(left_prefix + row);
        for (std::size_t j = 0; j < right_count; ++j) {
            const std::size_t columns = static_cast<std::size_t>(right_size[j]);
            std::int64_t previous[9]{}, current[9]{}, right_boundary[9]{};
            for (std::size_t col = 0; col <= columns; ++col) previous[col] = bottom[j][col];
            right_boundary[0] = previous[columns];
            const std::int64_t substitution = left_symbol[i] == right_symbol[j] ? 0 : 1;
            for (std::size_t row = 1; row <= rows; ++row) {
                current[0] = left_boundary[row];
                for (std::size_t col = 1; col <= columns; ++col) {
                    const auto deletion = previous[col] + 1;
                    const auto insertion = current[col - 1] + 1;
                    const auto replace = previous[col - 1] + substitution;
                    current[col] = deletion < insertion ? deletion : insertion;
                    if (replace < current[col]) current[col] = replace;
                }
                right_boundary[row] = current[columns];
                for (std::size_t col = 0; col <= columns; ++col) previous[col] = current[col];
            }
            for (std::size_t col = 0; col <= columns; ++col) next_bottom[j][col] = previous[col];
            for (std::size_t row = 0; row <= rows; ++row) left_boundary[row] = right_boundary[row];
        }
        for (std::size_t j = 0; j < right_count; ++j)
            for (std::size_t col = 0; col <= static_cast<std::size_t>(right_size[j]); ++col) bottom[j][col] = next_bottom[j][col];
        left_prefix += rows;
    }
    return bottom[right_count - 1][static_cast<std::size_t>(right_size[right_count - 1])];
}
