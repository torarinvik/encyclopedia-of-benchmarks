#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 6, MAX_COLUMNS = 8, MAX_INPUT = 17, MAX_STACK = 32 };

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte) output[byte] = (uint8_t)(bits >> (8 * byte));
}

static int interval_cover(const int *left, const int *right, int count,
                          const int64_t *weights, int columns,
                          int *out_cost, int *out_mask) {
    if (count == 0) { *out_cost = 0; *out_mask = 0; return 1; }
    int minimum_right = right[0], maximum_left = left[0];
    for (int i = 1; i < count; ++i) {
        if (right[i] < minimum_right) minimum_right = right[i];
        if (left[i] > maximum_left) maximum_left = left[i];
    }
    int costs[MAX_COLUMNS], masks[MAX_COLUMNS];
    for (int point = 0; point < columns; ++point) { costs[point] = 1000000; masks[point] = 0; }
    for (int point = 0; point < columns; ++point) {
        if (point <= minimum_right) {
            costs[point] = (int)weights[point];
            masks[point] = 1 << point;
        }
        for (int previous = 0; previous < point; ++previous) {
            if (costs[previous] == 1000000) continue;
            int blocked = 0;
            for (int i = 0; i < count; ++i)
                if (previous < left[i] && right[i] < point) { blocked = 1; break; }
            if (blocked) continue;
            int candidate_cost = costs[previous] + (int)weights[point];
            int candidate_mask = masks[previous] | (1 << point);
            if (candidate_cost < costs[point] ||
                (candidate_cost == costs[point] && candidate_mask < masks[point])) {
                costs[point] = candidate_cost;
                masks[point] = candidate_mask;
            }
        }
    }
    int best_cost = 1000000, best_mask = 0;
    for (int point = maximum_left; point < columns; ++point) {
        if (costs[point] < best_cost ||
            (costs[point] == best_cost && costs[point] != 1000000 && masks[point] < best_mask)) {
            best_cost = costs[point]; best_mask = masks[point];
        }
    }
    if (best_cost == 1000000) return 0;
    *out_cost = best_cost; *out_mask = best_mask;
    return 1;
}

int64_t ruf_schobel_set_cover(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS ||
        length != (size_t)(2 + rows_raw + columns_raw)) return -1;
    int rows = (int)rows_raw, columns = (int)columns_raw;
    int64_t weights[MAX_COLUMNS] = {0};
    uint64_t row_masks[MAX_ROWS] = {0};
    for (int column = 0; column < columns; ++column) {
        if (input[2 + column] < 1 || input[2 + column] > 20) return -1;
        weights[column] = input[2 + column];
    }
    uint64_t allowed = (UINT64_C(1) << columns) - 1;
    int block_left[MAX_ROWS][MAX_COLUMNS], block_right[MAX_ROWS][MAX_COLUMNS];
    int block_count[MAX_ROWS] = {0};
    for (int row = 0; row < rows; ++row) {
        int64_t raw = input[2 + columns + row];
        if (raw < 0 || ((uint64_t)raw & ~allowed) != 0) return -1;
        row_masks[row] = (uint64_t)raw;
        int column = 0;
        while (column < columns) {
            if ((row_masks[row] & (UINT64_C(1) << column)) == 0) { ++column; continue; }
            int index = block_count[row]++;
            block_left[row][index] = column;
            while (column + 1 < columns &&
                   (row_masks[row] & (UINT64_C(1) << (column + 1))) != 0) ++column;
            block_right[row][index] = column++;
        }
    }

    for (int row = 0; row < rows; ++row) {
        if (row_masks[row] == 0) {
            if (output == NULL || capacity < 8) return -2;
            store_i64_le(output, -1);
            return 8;
        }
    }

    int best_cost = 1000000;
    int stack[MAX_STACK][MAX_ROWS];
    int stack_size = 1;
    for (int row = 0; row < rows; ++row) stack[0][row] = -1;
    while (stack_size > 0) {
        --stack_size;
        int fixed[MAX_ROWS];
        for (int row = 0; row < rows; ++row) fixed[row] = stack[stack_size][row];
        int left[MAX_ROWS], right[MAX_ROWS], count = 0;
        for (int row = 0; row < rows; ++row) {
            if (block_count[row] == 1 || fixed[row] >= 0) {
                int block = block_count[row] == 1 ? 0 : fixed[row];
                left[count] = block_left[row][block];
                right[count++] = block_right[row][block];
            }
        }
        int lower_cost = 0, lower_mask = 0;
        if (!interval_cover(left, right, count, weights, columns, &lower_cost, &lower_mask)) continue;
        int extra_left[MAX_ROWS], extra_right[MAX_ROWS], extra_count = 0;
        for (int row = 0; row < rows; ++row) {
            if ((row_masks[row] & (uint64_t)lower_mask) != 0) continue;
            int chosen = 0, chosen_cost = 1000000;
            for (int block = 0; block < block_count[row]; ++block) {
                int cheapest = 1000000;
                for (int col = block_left[row][block]; col <= block_right[row][block]; ++col)
                    if ((int)weights[col] < cheapest) cheapest = (int)weights[col];
                if (cheapest < chosen_cost) { chosen_cost = cheapest; chosen = block; }
            }
            extra_left[extra_count] = block_left[row][chosen];
            extra_right[extra_count++] = block_right[row][chosen];
        }
        int extra_cost = 0, extra_mask = 0;
        if (!interval_cover(extra_left, extra_right, extra_count, weights, columns,
                            &extra_cost, &extra_mask)) continue;
        int candidate_mask = lower_mask | extra_mask, candidate_cost = 0;
        for (int col = 0; col < columns; ++col)
            if ((candidate_mask & (1 << col)) != 0) candidate_cost += (int)weights[col];
        if (candidate_cost < best_cost) best_cost = candidate_cost;
        if (best_cost <= lower_cost) continue;
        int branch = -1;
        for (int row = 0; row < rows; ++row)
            if (block_count[row] > 1 && fixed[row] < 0) { branch = row; break; }
        if (branch < 0) continue;
        for (int block = block_count[branch] - 1; block >= 0; --block) {
            for (int row = 0; row < rows; ++row) stack[stack_size][row] = fixed[row];
            stack[stack_size][branch] = block;
            ++stack_size;
        }
    }
    int64_t result = best_cost == 1000000 ? -1 : best_cost;
    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, result);
    return 8;
}
