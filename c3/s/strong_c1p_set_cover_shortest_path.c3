module strong_c1p_set_cover_shortest_path;

const usz MAX_ROWS = 8;
const usz MAX_COLUMNS = 10;
const usz MAX_INPUT = 21;
const long INF = 1000000000;

fn void store_i64_le(uint8* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[byte] = (uint8)(bits & 255); bits >>= 8; }
}

fn long solve(usz rows, usz columns, long* weights, long* row_left, long* row_right) {
    long[MAX_ROWS] order = zeroed;
    for (usz row = 0; row < rows; row += 1) order[row] = row.long();
    for (usz i = 1; i < rows; i += 1) {
        long value = order[i];
        usz j = i;
        while (j > 0 && row_left[order[j - 1].usz()] > row_left[value.usz()]) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = value;
    }
    long[MAX_ROWS] grouped_left = zeroed, grouped_right = zeroed;
    usz groups = 0;
    for (usz i = 0; i < rows; i += 1) {
        usz row = order[i].usz();
        if (groups == 0 || grouped_left[groups - 1] != row_left[row]) {
            grouped_left[groups] = row_left[row];
            grouped_right[groups] = row_right[row];
            groups += 1;
        } else if (row_right[row] < grouped_right[groups - 1]) {
            grouped_right[groups - 1] = row_right[row];
        }
    }
    long[MAX_ROWS] retained_left = zeroed, retained_right = zeroed;
    usz retained = 0;
    long suffix_minimum = columns.long();
    long i = groups.long() - 1;
    while i >= 0 {
        if (grouped_right[i.usz()] < suffix_minimum) {
            retained_left[retained] = grouped_left[i.usz()];
            retained_right[retained] = grouped_right[i.usz()];
            retained += 1;
            suffix_minimum = grouped_right[i.usz()];
        }
        i -= 1;
    }
    long[MAX_COLUMNS] column_start = zeroed, column_end = zeroed;
    for (usz col = 0; col < columns; col += 1) { column_start[col] = -1; column_end[col] = -1; }
    for (usz reduced_row = 0; reduced_row < retained; reduced_row += 1) {
        usz source = retained - 1 - reduced_row;
        usz col = retained_left[source].usz();
        while col <= retained_right[source].usz() {
            if (column_start[col] < 0) column_start[col] = reduced_row.long();
            column_end[col] = reduced_row.long();
            col += 1;
        }
    }
    long[MAX_COLUMNS] distance = zeroed;
    for (usz col = 0; col < columns; col += 1) {
        distance[col] = INF;
        if (column_start[col] == 0) distance[col] = 0;
    }
    long best = INF;
    for (usz from = 0; from < columns; from += 1) {
        if (distance[from] == INF) continue;
        if (column_end[from] == retained.long() - 1 && distance[from] + weights[from] < best)
            best = distance[from] + weights[from];
        for (usz to = from + 1; to < columns; to += 1) {
            if (column_start[to] >= 0 && column_start[to] <= column_end[from] + 1) {
                long candidate = distance[from] + weights[from];
                if (candidate < distance[to]) distance[to] = candidate;
            }
        }
    }
    if (best == INF) return -1;
    return best;
}

fn long strong_c1p_set_cover_shortest_path(long* input, usz length, uint8* output, usz capacity)
        @export("strong_c1p_set_cover_shortest_path") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS.long() || columns_raw < 1 || columns_raw > MAX_COLUMNS.long() ||
        length != 2 + rows_raw.usz() + columns_raw.usz()) return -1;
    usz rows = rows_raw.usz(), columns = columns_raw.usz();
    long[MAX_COLUMNS] weights = zeroed;
    for (usz col = 0; col < columns; col += 1) {
        if (input[2 + col] < 1 || input[2 + col] > 20) return -1;
        weights[col] = input[2 + col];
    }
    ulong allowed = (1ul << columns) - 1;
    long[MAX_ROWS] row_left = zeroed, row_right = zeroed;
    ulong[MAX_ROWS] masks = zeroed;
    bool infeasible = false;
    for (usz row = 0; row < rows; row += 1) {
        long raw = input[2 + columns + row];
        if (raw < 0 || ((ulong)raw & ~allowed) != 0) return -1;
        masks[row] = (ulong)raw;
        row_left[row] = columns.long();
        row_right[row] = -1;
        bool seen_one = false, seen_zero_after = false;
        for (usz col = 0; col < columns; col += 1) {
            if ((masks[row] & (1ul << col)) != 0) {
                if (seen_zero_after) return -1;
                seen_one = true;
                if (row_left[row] == columns.long()) row_left[row] = col.long();
                row_right[row] = col.long();
            } else if (seen_one) {
                seen_zero_after = true;
            }
        }
        if (masks[row] == 0) infeasible = true;
    }
    long result = -1;
    if (!infeasible) result = solve(rows, columns, &weights[0], &row_left[0], &row_right[0]);
    if (output == null || capacity < 8) return -2;
    store_i64_le(output, result);
    return 8;
}
