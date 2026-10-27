/* Run-length-native unit-cost edit distance by run-pair blocks. */
#include <stddef.h>
#include <stdint.h>

int64_t rle_levenshtein_block_dp(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 4 || length > 18) return -1;
    if (packed[0] < 1 || packed[0] > 4) return -1;
    const size_t left_count = (size_t)packed[0];
    const size_t right_count_index = 1 + 2 * left_count;
    if (right_count_index >= length || packed[right_count_index] < 1 || packed[right_count_index] > 4) return -1;
    const size_t right_count = (size_t)packed[right_count_index];
    if (length != right_count_index + 1 + 2 * right_count) return -1;
    int64_t left_symbol[4], left_size[4], right_symbol[4], right_size[4];
    size_t left_total = 0, right_total = 0;
    for (size_t run = 0; run < left_count; ++run) {
        left_symbol[run] = packed[1 + 2 * run]; left_size[run] = packed[2 + 2 * run];
        if (left_symbol[run] < 0 || left_symbol[run] > 3 || left_size[run] < 1 || left_size[run] > 8) return -1;
        left_total += (size_t)left_size[run]; if (left_total > 16) return -1;
    }
    for (size_t run = 0; run < right_count; ++run) {
        right_symbol[run] = packed[right_count_index + 1 + 2 * run];
        right_size[run] = packed[right_count_index + 2 + 2 * run];
        if (right_symbol[run] < 0 || right_symbol[run] > 3 || right_size[run] < 1 || right_size[run] > 8) return -1;
        right_total += (size_t)right_size[run]; if (right_total > 16) return -1;
    }
    int64_t bottom[4][9] = {{0}}, next_bottom[4][9] = {{0}};
    size_t right_prefix = 0;
    for (size_t j = 0; j < right_count; ++j) {
        for (size_t column = 0; column <= (size_t)right_size[j]; ++column) bottom[j][column] = (int64_t)(right_prefix + column);
        right_prefix += (size_t)right_size[j];
    }
    size_t left_prefix = 0;
    for (size_t i = 0; i < left_count; ++i) {
        const size_t rows = (size_t)left_size[i];
        int64_t left_boundary[9] = {0};
        for (size_t row = 0; row <= rows; ++row) left_boundary[row] = (int64_t)(left_prefix + row);
        for (size_t j = 0; j < right_count; ++j) {
            const size_t columns = (size_t)right_size[j];
            int64_t previous[9] = {0}, current[9] = {0}, right_boundary[9] = {0};
            for (size_t column = 0; column <= columns; ++column) previous[column] = bottom[j][column];
            right_boundary[0] = previous[columns];
            const int64_t substitution = left_symbol[i] == right_symbol[j] ? 0 : 1;
            for (size_t row = 1; row <= rows; ++row) {
                current[0] = left_boundary[row];
                for (size_t column = 1; column <= columns; ++column) {
                    int64_t deletion = previous[column] + 1;
                    int64_t insertion = current[column - 1] + 1;
                    int64_t replace = previous[column - 1] + substitution;
                    current[column] = deletion < insertion ? deletion : insertion;
                    if (replace < current[column]) current[column] = replace;
                }
                right_boundary[row] = current[columns];
                for (size_t column = 0; column <= columns; ++column) previous[column] = current[column];
            }
            for (size_t column = 0; column <= columns; ++column) next_bottom[j][column] = previous[column];
            for (size_t row = 0; row <= rows; ++row) left_boundary[row] = right_boundary[row];
        }
        for (size_t j = 0; j < right_count; ++j)
            for (size_t column = 0; column <= (size_t)right_size[j]; ++column) bottom[j][column] = next_bottom[j][column];
        left_prefix += rows;
    }
    return bottom[right_count - 1][(size_t)right_size[right_count - 1]];
}
