#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 8, MAX_COLUMNS = 10, MAX_INPUT = 21, MAX_OUTPUT_BYTES = 80 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t almost_c1p_set_cover_enumeration(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS ||
            length != (size_t)(2 + rows_raw + columns_raw)) return -1;
    const int rows = (int)rows_raw, columns = (int)columns_raw;
    int64_t weights[MAX_COLUMNS] = {0};
    uint64_t row_masks[MAX_ROWS] = {0};
    for (int column = 0; column < columns; ++column) {
        const int64_t weight = input[2 + column];
        if (weight < 1 || weight > 20) return -1;
        weights[column] = weight;
    }
    const uint64_t valid_mask = (UINT64_C(1) << columns) - 1;
    for (int row = 0; row < rows; ++row) {
        const int64_t raw_mask = input[2 + columns + row];
        if (raw_mask < 0 || ((uint64_t)raw_mask & ~valid_mask) != 0) return -1;
        row_masks[row] = (uint64_t)raw_mask;
    }

    const size_t state_count = (size_t)1 << columns;
    uint8_t feasible[1 << MAX_COLUMNS] = {0};
    feasible[0] = 1;
    for (int row = 0; row < rows; ++row) {
        const uint64_t cover_mask = row_masks[row];
        for (size_t selected = 0; selected < state_count; ++selected) {
            if (!feasible[selected] || (((uint64_t)selected & cover_mask) != 0)) continue;
            feasible[selected] = 0;
            for (int column = 0; column < columns; ++column) {
                const uint64_t bit = UINT64_C(1) << column;
                if ((cover_mask & bit) != 0) feasible[selected | bit] = 1;
            }
        }
    }

    int best_found = 0;
    uint64_t best_mask = 0;
    int64_t best_cost = 0;
    for (size_t selected = 0; selected < state_count; ++selected) {
        if (!feasible[selected]) continue;
        int64_t cost = 0;
        for (int column = 0; column < columns; ++column)
            if (((uint64_t)selected & (UINT64_C(1) << column)) != 0) cost += weights[column];
        if (!best_found || cost < best_cost || (cost == best_cost && (uint64_t)selected < best_mask)) {
            best_found = 1;
            best_mask = (uint64_t)selected;
            best_cost = cost;
        }
    }

    int selected_count = 0;
    if (best_found) {
        for (int column = 0; column < columns; ++column)
            if ((best_mask & (UINT64_C(1) << column)) != 0) ++selected_count;
    }
    const size_t output_words = best_found ? (size_t)(selected_count + 2) : 1u;
    const size_t output_bytes = 8u * output_words;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    if (!best_found) {
        store_i64_le(staged, 0, -1);
    } else {
        store_i64_le(staged, 0, selected_count);
        size_t cursor = 1;
        for (int column = 0; column < columns; ++column) {
            if ((best_mask & (UINT64_C(1) << column)) != 0)
                store_i64_le(staged, 8u * cursor++, column);
        }
        store_i64_le(staged, 8u * cursor, best_cost);
    }
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
