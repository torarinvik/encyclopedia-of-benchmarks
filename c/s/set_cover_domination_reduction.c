#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 8, MAX_COLUMNS = 8, MAX_INPUT = 19, MAX_OUTPUT = 272 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static uint64_t column_coverage(const uint64_t *masks, const uint8_t *active_rows,
                                int rows, int column) {
    uint64_t coverage = 0;
    for (int row = 0; row < rows; ++row)
        if (active_rows[row] && (masks[row] & (UINT64_C(1) << column)) != 0)
            coverage |= UINT64_C(1) << row;
    return coverage;
}

int64_t set_cover_domination_reduction(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS ||
        length != (size_t)(2 + rows_raw + columns_raw)) return -1;
    const int rows = (int)rows_raw, columns = (int)columns_raw;
    int64_t weights[MAX_COLUMNS] = {0};
    uint64_t masks[MAX_ROWS] = {0};
    uint8_t active_rows[MAX_ROWS] = {0}, active_columns[MAX_COLUMNS] = {0};
    for (int column = 0; column < columns; ++column) {
        const int64_t weight = input[2 + column];
        if (weight < 1 || weight > 20) return -1;
        weights[column] = weight;
        active_columns[column] = 1;
    }
    const uint64_t valid_columns = (UINT64_C(1) << columns) - 1;
    for (int row = 0; row < rows; ++row) {
        const int64_t raw = input[2 + columns + row];
        if (raw < 0 || ((uint64_t)raw & ~valid_columns) != 0) return -1;
        masks[row] = (uint64_t)raw;
        active_rows[row] = 1;
    }

    for (;;) {
        int changed = 0;
        for (int keep = 0; keep < rows && !changed; ++keep) {
            if (!active_rows[keep]) continue;
            for (int drop = 0; drop < rows; ++drop) {
                if (!active_rows[drop] || keep == drop) continue;
                if ((masks[keep] & ~masks[drop]) == 0 &&
                    (masks[keep] != masks[drop] || keep < drop)) {
                    active_rows[drop] = 0;
                    changed = 1;
                    break;
                }
            }
        }
        if (changed) continue;

        for (int drop = 0; drop < columns && !changed; ++drop) {
            if (!active_columns[drop]) continue;
            const uint64_t drop_cover = column_coverage(masks, active_rows, rows, drop);
            for (int keep = 0; keep < columns; ++keep) {
                if (!active_columns[keep] || keep == drop) continue;
                const uint64_t keep_cover = column_coverage(masks, active_rows, rows, keep);
                if ((drop_cover & ~keep_cover) == 0 && weights[drop] >= weights[keep] &&
                    (drop_cover != keep_cover || weights[drop] != weights[keep] || keep < drop)) {
                    active_columns[drop] = 0;
                    for (int row = 0; row < rows; ++row) masks[row] &= ~(UINT64_C(1) << drop);
                    changed = 1;
                    break;
                }
            }
        }
        if (changed) continue;

        for (int drop = 0; drop < columns && !changed; ++drop) {
            if (!active_columns[drop]) continue;
            const uint64_t drop_cover = column_coverage(masks, active_rows, rows, drop);
            for (int keep = 0; keep < columns; ++keep) {
                if (!active_columns[keep] || keep == drop) continue;
                const uint64_t keep_cover = column_coverage(masks, active_rows, rows, keep);
                const uint64_t exclusive_rows = drop_cover & ~keep_cover;
                if ((drop_cover & keep_cover) == 0 || exclusive_rows == 0) continue;
                uint64_t replacement_columns = 0;
                int feasible = 1;
                for (int row = 0; row < rows; ++row) {
                    if ((exclusive_rows & (UINT64_C(1) << row)) == 0) continue;
                    int minimum_column = -1;
                    for (int candidate = 0; candidate < columns; ++candidate) {
                        if (!active_columns[candidate] ||
                            (masks[row] & (UINT64_C(1) << candidate)) == 0) continue;
                        if (minimum_column < 0 || weights[candidate] < weights[minimum_column] ||
                            (weights[candidate] == weights[minimum_column] && candidate < minimum_column))
                            minimum_column = candidate;
                    }
                    if (minimum_column < 0) { feasible = 0; break; }
                    replacement_columns |= UINT64_C(1) << minimum_column;
                }
                int64_t replacement_cost = weights[keep];
                for (int candidate = 0; candidate < columns; ++candidate)
                    if ((replacement_columns & (UINT64_C(1) << candidate)) != 0)
                        replacement_cost += weights[candidate];
                if (feasible && weights[drop] >= replacement_cost) {
                    active_columns[drop] = 0;
                    for (int row = 0; row < rows; ++row) masks[row] &= ~(UINT64_C(1) << drop);
                    changed = 1;
                    break;
                }
            }
        }
        if (!changed) break;
    }

    int row_ids[MAX_ROWS], column_ids[MAX_COLUMNS], reduced_weights[MAX_COLUMNS];
    uint64_t reduced_masks[MAX_ROWS];
    int reduced_rows = 0, reduced_columns = 0;
    for (int row = 0; row < rows; ++row) if (active_rows[row]) row_ids[reduced_rows++] = row;
    for (int column = 0; column < columns; ++column) if (active_columns[column]) {
        column_ids[reduced_columns] = column;
        reduced_weights[reduced_columns++] = (int)weights[column];
    }
    for (int i = 0; i < reduced_rows; ++i) {
        uint64_t compact = 0;
        for (int j = 0; j < reduced_columns; ++j)
            if ((masks[row_ids[i]] & (UINT64_C(1) << column_ids[j])) != 0)
                compact |= UINT64_C(1) << j;
        reduced_masks[i] = compact;
    }
    const size_t words = (size_t)(2 + 2 * reduced_rows + 2 * reduced_columns);
    const size_t bytes = 8 * words;
    uint8_t staged[MAX_OUTPUT] = {0};
    size_t cursor = 0;
    store_i64_le(staged, 8 * cursor++, reduced_rows);
    store_i64_le(staged, 8 * cursor++, reduced_columns);
    for (int i = 0; i < reduced_rows; ++i) store_i64_le(staged, 8 * cursor++, row_ids[i]);
    for (int i = 0; i < reduced_columns; ++i) store_i64_le(staged, 8 * cursor++, column_ids[i]);
    for (int i = 0; i < reduced_columns; ++i) store_i64_le(staged, 8 * cursor++, reduced_weights[i]);
    for (int i = 0; i < reduced_rows; ++i) store_i64_le(staged, 8 * cursor++, (int64_t)reduced_masks[i]);
    if (output == NULL || capacity < bytes) return -2;
    for (size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)bytes;
}
