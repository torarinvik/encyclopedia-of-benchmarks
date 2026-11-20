#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define B3_MAX_DIM 5
#define B3_MAX_PAT_DIM 4
#define B3_MAX_INPUT 196
#define B3_MAX_MATCHES 125

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static bool pattern_rows_equal(const int64_t *pattern, size_t row_a,
                               size_t row_b, size_t width) {
    for (size_t column = 0; column < width; ++column)
        if (pattern[row_a * width + column] != pattern[row_b * width + column]) return false;
    return true;
}

int64_t three_dimensional_bird_baker_matching(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 7 || length > B3_MAX_INPUT) return -1;
    const int64_t rows0 = input[0], columns0 = input[1], depths0 = input[2];
    const int64_t pattern_rows0 = input[3], pattern_columns0 = input[4], pattern_depths0 = input[5];
    if (rows0 < 1 || rows0 > B3_MAX_DIM || columns0 < 1 || columns0 > B3_MAX_DIM
            || depths0 < 1 || depths0 > B3_MAX_DIM
            || pattern_rows0 < 1 || pattern_rows0 > B3_MAX_PAT_DIM
            || pattern_columns0 < 1 || pattern_columns0 > B3_MAX_PAT_DIM
            || pattern_depths0 < 1 || pattern_depths0 > B3_MAX_PAT_DIM
            || pattern_rows0 > rows0 || pattern_columns0 > columns0 || pattern_depths0 > depths0)
        return -1;
    const size_t rows = (size_t)rows0, columns = (size_t)columns0, depths = (size_t)depths0;
    const size_t pattern_rows = (size_t)pattern_rows0, pattern_columns = (size_t)pattern_columns0;
    const size_t pattern_depths = (size_t)pattern_depths0;
    const size_t text_size = rows * columns * depths;
    const size_t pattern_size = pattern_rows * pattern_columns * pattern_depths;
    if (length != 6 + text_size + pattern_size) return -1;

    int64_t text[B3_MAX_DIM * B3_MAX_DIM * B3_MAX_DIM];
    int64_t pattern[B3_MAX_PAT_DIM * B3_MAX_PAT_DIM * B3_MAX_PAT_DIM];
    for (size_t i = 0; i < text_size; ++i) {
        text[i] = input[6 + i];
        if (text[i] < 0 || text[i] > 3) return -1;
    }
    for (size_t i = 0; i < pattern_size; ++i) {
        pattern[i] = input[6 + text_size + i];
        if (pattern[i] < 0 || pattern[i] > 3) return -1;
    }

    size_t plane_id[B3_MAX_PAT_DIM] = {0};
    int64_t unique_planes[B3_MAX_PAT_DIM][B3_MAX_PAT_DIM * B3_MAX_PAT_DIM] = {{0}};
    size_t unique_count = 0;
    const size_t plane_area = pattern_rows * pattern_columns;
    for (size_t pz = 0; pz < pattern_depths; ++pz) {
        size_t found = unique_count;
        for (size_t candidate = 0; candidate < unique_count; ++candidate) {
            bool equal = true;
            for (size_t i = 0; i < plane_area; ++i)
                if (unique_planes[candidate][i] != pattern[pz * plane_area + i]) equal = false;
            if (equal) { found = candidate; break; }
        }
        if (found == unique_count) {
            for (size_t i = 0; i < plane_area; ++i)
                unique_planes[unique_count][i] = pattern[pz * plane_area + i];
            ++unique_count;
        }
        plane_id[pz] = found;
    }

    const size_t row_starts = rows - pattern_rows + 1;
    const size_t column_starts = columns - pattern_columns + 1;
    int8_t labels[B3_MAX_DIM][B3_MAX_DIM][B3_MAX_DIM];
    for (size_t z = 0; z < depths; ++z)
        for (size_t r = 0; r < row_starts; ++r)
            for (size_t c = 0; c < column_starts; ++c) labels[z][r][c] = -1;

    for (size_t z = 0; z < depths; ++z) {
        for (size_t unique = 0; unique < unique_count; ++unique) {
            bool row_match[B3_MAX_DIM][B3_MAX_DIM][B3_MAX_PAT_DIM] = {{{false}}};
            size_t prefix[B3_MAX_PAT_DIM] = {0};
            for (size_t i = 1; i < pattern_rows; ++i) {
                size_t matched = prefix[i - 1];
                while (matched > 0 && !pattern_rows_equal(unique_planes[unique], i, matched, pattern_columns))
                    matched = prefix[matched - 1];
                if (pattern_rows_equal(unique_planes[unique], i, matched, pattern_columns)) ++matched;
                prefix[i] = matched;
            }
            for (size_t r = 0; r < rows; ++r) {
                for (size_t c = 0; c < column_starts; ++c) {
                    for (size_t pr = 0; pr < pattern_rows; ++pr) {
                        bool equal = true;
                        for (size_t pc = 0; pc < pattern_columns; ++pc) {
                            const size_t text_index = (z * rows + r) * columns + c + pc;
                            if (text[text_index] != unique_planes[unique][pr * pattern_columns + pc]) equal = false;
                        }
                        row_match[r][c][pr] = equal;
                    }
                }
            }
            for (size_t c = 0; c < column_starts; ++c) {
                size_t matched = 0;
                for (size_t r = 0; r < rows; ++r) {
                    while (matched > 0 && !row_match[r][c][matched]) matched = prefix[matched - 1];
                    if (row_match[r][c][matched]) ++matched;
                    if (matched == pattern_rows) {
                        labels[z][r + 1 - pattern_rows][c] = (int8_t)unique;
                        matched = prefix[matched - 1];
                    }
                }
            }
        }
    }

    size_t prefix[B3_MAX_PAT_DIM] = {0};
    for (size_t i = 1; i < pattern_depths; ++i) {
        size_t matched = prefix[i - 1];
        while (matched > 0 && plane_id[i] != plane_id[matched]) matched = prefix[matched - 1];
        if (plane_id[i] == plane_id[matched]) ++matched;
        prefix[i] = matched;
    }
    int64_t match_rows[B3_MAX_MATCHES], match_columns[B3_MAX_MATCHES], match_depths[B3_MAX_MATCHES];
    size_t match_count = 0;
    for (size_t r = 0; r < row_starts; ++r) {
        for (size_t c = 0; c < column_starts; ++c) {
            size_t matched = 0;
            for (size_t z = 0; z < depths; ++z) {
                const int64_t label = labels[z][r][c];
                while (matched > 0 && label != (int64_t)plane_id[matched]) matched = prefix[matched - 1];
                if (label == (int64_t)plane_id[matched]) ++matched;
                if (matched == pattern_depths) {
                    match_rows[match_count] = (int64_t)r;
                    match_columns[match_count] = (int64_t)c;
                    match_depths[match_count] = (int64_t)(z + 1 - pattern_depths);
                    ++match_count;
                    matched = prefix[matched - 1];
                }
            }
        }
    }

    const size_t bytes = 8 * (1 + 3 * match_count);
    if (output == NULL || capacity < bytes) return -2;
    put_i64_le(output, 0, (int64_t)match_count);
    for (size_t i = 0; i < match_count; ++i) {
        put_i64_le(output, 8 * (1 + 3 * i), match_rows[i]);
        put_i64_le(output, 8 * (2 + 3 * i), match_columns[i]);
        put_i64_le(output, 8 * (3 + 3 * i), match_depths[i]);
    }
    return (int64_t)bytes;
}
