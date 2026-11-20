module set_cover_domination_reduction;

const usz MAX_ROWS = 8;
const usz MAX_COLUMNS = 8;
const usz MAX_INPUT = 19;
const usz MAX_OUTPUT = 272;

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (uint8)(bits & 255); bits >>= 8; }
}

fn ulong column_coverage(ulong* masks, bool* active_rows, usz rows, usz column) {
    ulong coverage = 0;
    for (usz row = 0; row < rows; row += 1)
        if (active_rows[row] && (masks[row] & (1ul << column)) != 0) coverage |= 1ul << row;
    return coverage;
}

fn long set_cover_domination_reduction(long* input, usz length, uint8* output, usz capacity)
        @export("set_cover_domination_reduction") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS.long() || columns_raw < 1 || columns_raw > MAX_COLUMNS.long() ||
        length != 2 + rows_raw.usz() + columns_raw.usz()) return -1;
    usz rows = rows_raw.usz(), columns = columns_raw.usz();
    long[MAX_COLUMNS] weights = zeroed;
    bool[MAX_COLUMNS] active_columns = zeroed;
    for (usz column = 0; column < columns; column += 1) {
        long weight = input[2 + column];
        if (weight < 1 || weight > 20) return -1;
        weights[column] = weight;
        active_columns[column] = true;
    }
    ulong valid_columns = (1ul << columns) - 1;
    ulong[MAX_ROWS] masks = zeroed;
    bool[MAX_ROWS] active_rows = zeroed;
    for (usz row = 0; row < rows; row += 1) {
        long raw = input[2 + columns + row];
        if (raw < 0 || ((ulong)raw & ~valid_columns) != 0) return -1;
        masks[row] = (ulong)raw;
        active_rows[row] = true;
    }

    while (true) {
        bool changed = false;
        for (usz keep = 0; keep < rows && !changed; keep += 1) {
            if (!active_rows[keep]) continue;
            for (usz drop = 0; drop < rows; drop += 1) {
                if (!active_rows[drop] || keep == drop) continue;
                if ((masks[keep] & ~masks[drop]) == 0 && (masks[keep] != masks[drop] || keep < drop)) {
                    active_rows[drop] = false; changed = true; break;
                }
            }
        }
        if (changed) continue;

        for (usz drop = 0; drop < columns && !changed; drop += 1) {
            if (!active_columns[drop]) continue;
            ulong drop_cover = column_coverage(&masks[0], &active_rows[0], rows, drop);
            for (usz keep = 0; keep < columns; keep += 1) {
                if (!active_columns[keep] || keep == drop) continue;
                ulong keep_cover = column_coverage(&masks[0], &active_rows[0], rows, keep);
                if ((drop_cover & ~keep_cover) == 0 && weights[drop] >= weights[keep] &&
                    (drop_cover != keep_cover || weights[drop] != weights[keep] || keep < drop)) {
                    active_columns[drop] = false;
                    for (usz row = 0; row < rows; row += 1) masks[row] &= ~(1ul << drop);
                    changed = true; break;
                }
            }
        }
        if (changed) continue;

        for (usz drop = 0; drop < columns && !changed; drop += 1) {
            if (!active_columns[drop]) continue;
            ulong drop_cover = column_coverage(&masks[0], &active_rows[0], rows, drop);
            for (usz keep = 0; keep < columns; keep += 1) {
                if (!active_columns[keep] || keep == drop) continue;
                ulong keep_cover = column_coverage(&masks[0], &active_rows[0], rows, keep);
                ulong exclusive_rows = drop_cover & ~keep_cover;
                if ((drop_cover & keep_cover) == 0 || exclusive_rows == 0) continue;
                ulong replacement_columns = 0;
                bool feasible = true;
                for (usz row = 0; row < rows; row += 1) {
                    if ((exclusive_rows & (1ul << row)) == 0) continue;
                    usz minimum_column = columns;
                    for (usz candidate = 0; candidate < columns; candidate += 1) {
                        if (!active_columns[candidate] || (masks[row] & (1ul << candidate)) == 0) continue;
                        if (minimum_column == columns || weights[candidate] < weights[minimum_column] ||
                            (weights[candidate] == weights[minimum_column] && candidate < minimum_column))
                            minimum_column = candidate;
                    }
                    if (minimum_column == columns) { feasible = false; break; }
                    replacement_columns |= 1ul << minimum_column;
                }
                long replacement_cost = weights[keep];
                for (usz candidate = 0; candidate < columns; candidate += 1)
                    if ((replacement_columns & (1ul << candidate)) != 0) replacement_cost += weights[candidate];
                if (feasible && weights[drop] >= replacement_cost) {
                    active_columns[drop] = false;
                    for (usz row = 0; row < rows; row += 1) masks[row] &= ~(1ul << drop);
                    changed = true; break;
                }
            }
        }
        if (!changed) break;
    }

    long[MAX_ROWS] row_ids = zeroed;
    long[MAX_COLUMNS] column_ids = zeroed;
    usz reduced_rows = 0, reduced_columns = 0;
    for (usz row = 0; row < rows; row += 1) if (active_rows[row]) { row_ids[reduced_rows] = row.long(); reduced_rows += 1; }
    for (usz column = 0; column < columns; column += 1)
        if (active_columns[column]) { column_ids[reduced_columns] = column.long(); reduced_columns += 1; }
    ulong[MAX_ROWS] reduced_masks = zeroed;
    for (usz i = 0; i < reduced_rows; i += 1)
        for (usz j = 0; j < reduced_columns; j += 1)
            if ((masks[row_ids[i].usz()] & (1ul << column_ids[j].usz())) != 0) reduced_masks[i] |= 1ul << j;
    usz words = 2 + 2 * reduced_rows + 2 * reduced_columns;
    usz bytes = 8 * words;
    uint8[MAX_OUTPUT] staged = zeroed;
    usz cursor = 0;
    store_i64_le(&staged[0], 8 * cursor, reduced_rows.long()); cursor += 1;
    store_i64_le(&staged[0], 8 * cursor, reduced_columns.long()); cursor += 1;
    for (usz i = 0; i < reduced_rows; i += 1) { store_i64_le(&staged[0], 8 * cursor, row_ids[i]); cursor += 1; }
    for (usz i = 0; i < reduced_columns; i += 1) { store_i64_le(&staged[0], 8 * cursor, column_ids[i]); cursor += 1; }
    for (usz i = 0; i < reduced_columns; i += 1) { store_i64_le(&staged[0], 8 * cursor, weights[column_ids[i].usz()]); cursor += 1; }
    for (usz i = 0; i < reduced_rows; i += 1) { store_i64_le(&staged[0], 8 * cursor, reduced_masks[i].long()); cursor += 1; }
    if (output == null || capacity < bytes) return -2;
    for (usz byte = 0; byte < bytes; byte += 1) output[byte] = staged[byte];
    return bytes.long();
}
