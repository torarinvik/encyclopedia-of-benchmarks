/* Run-length-native LCS by run-pair blocks and boundary propagation. */
#include <stddef.h>
#include <stdint.h>

int64_t rle_lcs_block_dp(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 4 || length > 18) return -1;
    const int64_t left_count_value = packed[0];
    if (left_count_value < 1 || left_count_value > 4) return -1;
    const size_t left_count = (size_t)left_count_value;
    const size_t right_count_index = 1 + 2 * left_count;
    if (right_count_index >= length) return -1;
    const int64_t right_count_value = packed[right_count_index];
    if (right_count_value < 1 || right_count_value > 4 ||
        length != right_count_index + 1 + 2 * (size_t)right_count_value) return -1;
    const size_t right_count = (size_t)right_count_value;
    int64_t left_symbol[4], left_size[4], right_symbol[4], right_size[4];
    size_t left_total = 0, right_total = 0;
    for (size_t run = 0; run < left_count; ++run) {
        const int64_t symbol = packed[1 + 2 * run];
        const int64_t size = packed[2 + 2 * run];
        if (symbol < 0 || symbol > 3 || size < 1 || size > 8) return -1;
        left_total += (size_t)size;
        if (left_total > 16) return -1;
        left_symbol[run] = symbol; left_size[run] = size;
    }
    for (size_t run = 0; run < right_count; ++run) {
        const int64_t symbol = packed[right_count_index + 1 + 2 * run];
        const int64_t size = packed[right_count_index + 2 + 2 * run];
        if (symbol < 0 || symbol > 3 || size < 1 || size > 8) return -1;
        right_total += (size_t)size;
        if (right_total > 16) return -1;
        right_symbol[run] = symbol; right_size[run] = size;
    }

    int64_t bottom[4][9] = {{0}}, next_bottom[4][9] = {{0}};
    for (size_t i = 0; i < left_count; ++i) {
        int64_t left_boundary[9] = {0};
        for (size_t j = 0; j < right_count; ++j) {
            const size_t rows = (size_t)left_size[i], columns = (size_t)right_size[j];
            int64_t previous[9] = {0}, current[9] = {0}, right_boundary[9] = {0};
            for (size_t column = 0; column <= columns; ++column) previous[column] = bottom[j][column];
            right_boundary[0] = previous[columns];
            for (size_t row = 1; row <= rows; ++row) {
                current[0] = left_boundary[row];
                for (size_t column = 1; column <= columns; ++column) {
                    if (left_symbol[i] == right_symbol[j]) current[column] = previous[column - 1] + 1;
                    else current[column] = previous[column] > current[column - 1] ? previous[column] : current[column - 1];
                }
                right_boundary[row] = current[columns];
                for (size_t column = 0; column <= columns; ++column) previous[column] = current[column];
            }
            for (size_t column = 0; column <= columns; ++column) next_bottom[j][column] = previous[column];
            for (size_t row = 0; row <= rows; ++row) left_boundary[row] = right_boundary[row];
        }
        for (size_t j = 0; j < right_count; ++j)
            for (size_t column = 0; column <= (size_t)right_size[j]; ++column)
                bottom[j][column] = next_bottom[j][column];
    }
    return bottom[right_count - 1][(size_t)right_size[right_count - 1]];
}
