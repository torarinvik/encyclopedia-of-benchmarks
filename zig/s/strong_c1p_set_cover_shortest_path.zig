const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 10;
const MAX_INPUT: usize = 21;
const INF: i64 = 1_000_000_000;

fn storeI64Le(output: []u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

fn solve(
    rows: usize,
    columns: usize,
    weights: [MAX_COLUMNS]i64,
    row_left: [MAX_ROWS]usize,
    row_right: [MAX_ROWS]usize,
) i64 {
    var order: [MAX_ROWS]usize = @splat(0);
    for (0..rows) |row| order[row] = row;
    for (1..rows) |i| {
        const value = order[i];
        var j = i;
        while (j > 0 and row_left[order[j - 1]] > row_left[value]) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = value;
    }

    var grouped_left: [MAX_ROWS]usize = @splat(0);
    var grouped_right: [MAX_ROWS]usize = @splat(0);
    var groups: usize = 0;
    for (0..rows) |i| {
        const row = order[i];
        if (groups == 0 or grouped_left[groups - 1] != row_left[row]) {
            grouped_left[groups] = row_left[row];
            grouped_right[groups] = row_right[row];
            groups += 1;
        } else if (row_right[row] < grouped_right[groups - 1]) {
            grouped_right[groups - 1] = row_right[row];
        }
    }

    var retained_left: [MAX_ROWS]usize = @splat(0);
    var retained_right: [MAX_ROWS]usize = @splat(0);
    var retained: usize = 0;
    var suffix_minimum = columns;
    for (0..groups) |offset| {
        const i = groups - 1 - offset;
        if (grouped_right[i] < suffix_minimum) {
            retained_left[retained] = grouped_left[i];
            retained_right[retained] = grouped_right[i];
            retained += 1;
            suffix_minimum = grouped_right[i];
        }
    }

    var column_start: [MAX_COLUMNS]i32 = @splat(-1);
    var column_end: [MAX_COLUMNS]i32 = @splat(-1);
    for (0..retained) |reduced_row| {
        const source = retained - 1 - reduced_row;
        for (retained_left[source]..retained_right[source] + 1) |column| {
            if (column_start[column] < 0) column_start[column] = @intCast(reduced_row);
            column_end[column] = @intCast(reduced_row);
        }
    }

    var distance: [MAX_COLUMNS]i64 = @splat(INF);
    for (0..columns) |column| {
        if (column_start[column] == 0) distance[column] = 0;
    }
    var best: i64 = INF;
    for (0..columns) |from| {
        if (distance[from] == INF) continue;
        if (column_end[from] == @as(i32, @intCast(retained)) - 1) {
            best = @min(best, distance[from] + weights[from]);
        }
        for (from + 1..columns) |to| {
            if (column_start[to] >= 0 and column_start[to] <= column_end[from] + 1) {
                distance[to] = @min(distance[to], distance[from] + weights[from]);
            }
        }
    }
    if (best == INF) return -1;
    return best;
}

export fn strong_c1p_set_cover_shortest_path(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 4 or length > MAX_INPUT) return -1;
    const values = input.?;
    const rows_raw = values[0];
    const columns_raw = values[1];
    if (rows_raw < 1 or rows_raw > MAX_ROWS or columns_raw < 1 or columns_raw > MAX_COLUMNS) return -1;
    const rows: usize = @intCast(rows_raw);
    const columns: usize = @intCast(columns_raw);
    if (length != 2 + rows + columns) return -1;
    var weights: [MAX_COLUMNS]i64 = @splat(0);
    for (0..columns) |column| {
        const weight = values[2 + column];
        if (weight < 1 or weight > 20) return -1;
        weights[column] = weight;
    }
    const allowed = (@as(u64, 1) << @intCast(columns)) - 1;
    var masks: [MAX_ROWS]u64 = @splat(0);
    var row_left: [MAX_ROWS]usize = @splat(0);
    var row_right: [MAX_ROWS]usize = @splat(0);
    var infeasible = false;
    for (0..rows) |row| {
        const raw = values[2 + columns + row];
        if (raw < 0 or (@as(u64, @intCast(raw)) & ~allowed) != 0) return -1;
        masks[row] = @intCast(raw);
        row_left[row] = columns;
        row_right[row] = 0;
        var seen_one = false;
        var seen_zero_after = false;
        for (0..columns) |column| {
            if ((masks[row] & (@as(u64, 1) << @intCast(column))) != 0) {
                if (seen_zero_after) return -1;
                seen_one = true;
                if (row_left[row] == columns) row_left[row] = column;
                row_right[row] = column;
            } else if (seen_one) {
                seen_zero_after = true;
            }
        }
        if (masks[row] == 0) infeasible = true;
    }
    const result: i64 = if (infeasible) -1 else solve(rows, columns, weights, row_left, row_right);
    if (output == null or capacity < 8) return -2;
    var staged: [8]u8 = undefined;
    storeI64Le(staged[0..], result);
    @memcpy(output.?[0..8], staged[0..]);
    return 8;
}
