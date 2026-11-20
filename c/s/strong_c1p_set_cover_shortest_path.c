#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 8, MAX_COLUMNS = 10, MAX_INPUT = 21, INF = 1000000000 };

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte) output[byte] = (uint8_t)(bits >> (8 * byte));
}

static int solve(int rows, int columns, const int64_t *weights,
                 const int *row_left, const int *row_right) {
    int order[MAX_ROWS];
    for (int row = 0; row < rows; ++row) order[row] = row;
    for (int i = 1; i < rows; ++i) {
        int value = order[i], j = i;
        while (j > 0 && row_left[order[j - 1]] > row_left[value]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = value;
    }

    int grouped_left[MAX_ROWS], grouped_right[MAX_ROWS], groups = 0;
    for (int i = 0; i < rows; ++i) {
        int row = order[i];
        if (groups == 0 || grouped_left[groups - 1] != row_left[row]) {
            grouped_left[groups] = row_left[row];
            grouped_right[groups++] = row_right[row];
        } else if (row_right[row] < grouped_right[groups - 1]) {
            grouped_right[groups - 1] = row_right[row];
        }
    }
    int retained_left[MAX_ROWS], retained_right[MAX_ROWS], retained = 0;
    int suffix_minimum = columns;
    for (int i = groups - 1; i >= 0; --i) {
        if (grouped_right[i] < suffix_minimum) {
            retained_left[retained] = grouped_left[i];
            retained_right[retained++] = grouped_right[i];
            suffix_minimum = grouped_right[i];
        }
    }

    int column_start[MAX_COLUMNS], column_end[MAX_COLUMNS];
    for (int column = 0; column < columns; ++column) {
        column_start[column] = -1;
        column_end[column] = -1;
    }
    for (int i = 0; i < retained; ++i) {
        int source = retained - 1 - i;
        int reduced_row = i;
        for (int column = retained_left[source]; column <= retained_right[source]; ++column) {
            if (column_start[column] < 0) column_start[column] = reduced_row;
            column_end[column] = reduced_row;
        }
    }

    int distance[MAX_COLUMNS];
    for (int column = 0; column < columns; ++column) {
        distance[column] = INF;
        if (column_start[column] == 0) distance[column] = 0;
    }
    int best = INF;
    for (int from = 0; from < columns; ++from) {
        if (distance[from] == INF) continue;
        if (column_end[from] == retained - 1 && distance[from] + weights[from] < best)
            best = distance[from] + (int)weights[from];
        for (int to = from + 1; to < columns; ++to) {
            if (column_start[to] >= 0 && column_start[to] <= column_end[from] + 1) {
                int candidate = distance[from] + (int)weights[from];
                if (candidate < distance[to]) distance[to] = candidate;
            }
        }
    }
    return best == INF ? -1 : best;
}

int64_t strong_c1p_set_cover_shortest_path(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS ||
        length != (size_t)(2 + rows_raw + columns_raw)) return -1;
    int rows = (int)rows_raw, columns = (int)columns_raw;
    int64_t weights[MAX_COLUMNS] = {0};
    uint64_t masks[MAX_ROWS] = {0};
    int row_left[MAX_ROWS] = {0}, row_right[MAX_ROWS] = {0};
    int infeasible = 0;
    for (int column = 0; column < columns; ++column) {
        if (input[2 + column] < 1 || input[2 + column] > 20) return -1;
        weights[column] = input[2 + column];
    }
    uint64_t allowed = (UINT64_C(1) << columns) - 1;
    for (int row = 0; row < rows; ++row) {
        int64_t raw = input[2 + columns + row];
        if (raw < 0 || ((uint64_t)raw & ~allowed) != 0) return -1;
        masks[row] = (uint64_t)raw;
        int seen_one = 0, seen_zero_after = 0;
        row_left[row] = columns;
        row_right[row] = -1;
        for (int column = 0; column < columns; ++column) {
            if ((masks[row] & (UINT64_C(1) << column)) != 0) {
                if (seen_zero_after) return -1;
                seen_one = 1;
                if (row_left[row] == columns) row_left[row] = column;
                row_right[row] = column;
            } else if (seen_one) {
                seen_zero_after = 1;
            }
        }
        if (masks[row] == 0) infeasible = 1;
    }
    int result = infeasible ? -1 : solve(rows, columns, weights, row_left, row_right);
    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, result);
    return 8;
}
