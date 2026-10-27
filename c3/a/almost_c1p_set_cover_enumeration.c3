module almost_c1p_set_cover_enumeration;

const usz MAX_ROWS = 8;
const usz MAX_COLUMNS = 10;
const usz MAX_OUTPUT_BYTES = 80;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long almost_c1p_set_cover_enumeration(long* input, usz length, char* output, usz capacity)
        @export("almost_c1p_set_cover_enumeration") {
    if (input == null || length < 4 || length > 21) return -1;
    long rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS.long() || columns_raw < 1 || columns_raw > MAX_COLUMNS.long() ||
            length != 2 + rows_raw.usz() + columns_raw.usz()) return -1;
    usz rows = rows_raw.usz(), columns = columns_raw.usz();
    long[MAX_COLUMNS] weights = zeroed;
    for (usz column = 0; column < columns; column += 1) {
        long weight = input[2 + column];
        if (weight < 1 || weight > 20) return -1;
        weights[column] = weight;
    }
    ulong valid_mask = (1ul << columns) - 1;
    ulong[MAX_ROWS] row_masks = zeroed;
    for (usz row = 0; row < rows; row += 1) {
        long raw_mask = input[2 + columns + row];
        if (raw_mask < 0 || ((ulong)raw_mask & ~valid_mask) != 0) return -1;
        row_masks[row] = (ulong)raw_mask;
    }

    usz state_count = 1 << columns;
    bool[1 << MAX_COLUMNS] feasible = zeroed;
    feasible[0] = true;
    for (usz row = 0; row < rows; row += 1) {
        ulong cover_mask = row_masks[row];
        for (usz selected = 0; selected < state_count; selected += 1) {
            if (!feasible[selected] || (((ulong)selected & cover_mask) != 0)) continue;
            feasible[selected] = false;
            for (usz column = 0; column < columns; column += 1) {
                usz bit = 1 << column;
                if ((cover_mask & (ulong)bit) != 0) feasible[selected | bit] = true;
            }
        }
    }

    bool best_found = false;
    ulong best_mask = 0;
    long best_cost = 0;
    for (usz selected = 0; selected < state_count; selected += 1) {
        if (!feasible[selected]) continue;
        long cost = 0;
        for (usz column = 0; column < columns; column += 1)
            if (((ulong)selected & (1ul << column)) != 0) cost += weights[column];
        if (!best_found || cost < best_cost || (cost == best_cost && (ulong)selected < best_mask)) {
            best_found = true; best_mask = (ulong)selected; best_cost = cost;
        }
    }
    usz selected_count = 0;
    if (best_found) for (usz column = 0; column < columns; column += 1)
        if ((best_mask & (1ul << column)) != 0) selected_count += 1;
    usz output_bytes = if best_found then 8 * (selected_count + 2) else 8;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    if (best_found) {
        store_i64_le(&staged[0], 0, selected_count.long());
        usz cursor = 1;
        for (usz column = 0; column < columns; column += 1) {
            if ((best_mask & (1ul << column)) != 0) {
                store_i64_le(&staged[0], 8 * cursor, column.long());
                cursor += 1;
            }
        }
        store_i64_le(&staged[0], 8 * cursor, best_cost);
    } else store_i64_le(&staged[0], 0, -1);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
