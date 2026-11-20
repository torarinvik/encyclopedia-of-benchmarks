const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 8;
const MAX_INPUT: usize = 19;
const MAX_OUTPUT: usize = 272;

fn storeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn columnCoverage(masks: *[MAX_ROWS]u64, active_rows: *[MAX_ROWS]bool, rows: usize, column: usize) u64 {
    var coverage: u64 = 0;
    for (0..rows) |row| {
        if (active_rows[row] and masks[row] & (@as(u64, 1) << @intCast(column)) != 0)
            coverage |= @as(u64, 1) << @intCast(row);
    }
    return coverage;
}

export fn set_cover_domination_reduction(
    input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize,
) i64 {
    if (input == null or length < 4 or length > MAX_INPUT) return -1;
    const values = input.?;
    const rows_raw = values[0];
    const columns_raw = values[1];
    if (rows_raw < 1 or rows_raw > @as(i64, @intCast(MAX_ROWS)) or
        columns_raw < 1 or columns_raw > @as(i64, @intCast(MAX_COLUMNS)) or
        length != 2 + @as(usize, @intCast(rows_raw)) + @as(usize, @intCast(columns_raw))) return -1;
    const rows: usize = @intCast(rows_raw);
    const columns: usize = @intCast(columns_raw);
    var weights: [MAX_COLUMNS]i64 = @splat(0);
    var masks: [MAX_ROWS]u64 = @splat(0);
    var active_rows: [MAX_ROWS]bool = @splat(false);
    var active_columns: [MAX_COLUMNS]bool = @splat(false);
    for (0..columns) |column| {
        const weight = values[2 + column];
        if (weight < 1 or weight > 20) return -1;
        weights[column] = weight;
        active_columns[column] = true;
    }
    const valid_columns = (@as(u64, 1) << @intCast(columns)) - 1;
    for (0..rows) |row| {
        const raw = values[2 + columns + row];
        if (raw < 0 or (@as(u64, @intCast(raw)) & ~valid_columns) != 0) return -1;
        masks[row] = @intCast(raw);
        active_rows[row] = true;
    }

    while (true) {
        var changed = false;
        for (0..rows) |keep| {
            if (!active_rows[keep]) continue;
            for (0..rows) |drop| {
                if (!active_rows[drop] or keep == drop) continue;
                if (masks[keep] & ~masks[drop] == 0 and (masks[keep] != masks[drop] or keep < drop)) {
                    active_rows[drop] = false;
                    changed = true;
                    break;
                }
            }
            if (changed) break;
        }
        if (changed) continue;

        for (0..columns) |drop| {
            if (!active_columns[drop]) continue;
            const drop_cover = columnCoverage(&masks, &active_rows, rows, drop);
            for (0..columns) |keep| {
                if (!active_columns[keep] or keep == drop) continue;
                const keep_cover = columnCoverage(&masks, &active_rows, rows, keep);
                if (drop_cover & ~keep_cover == 0 and weights[drop] >= weights[keep] and
                    (drop_cover != keep_cover or weights[drop] != weights[keep] or keep < drop)) {
                    active_columns[drop] = false;
                    for (0..rows) |row| masks[row] &= ~(@as(u64, 1) << @intCast(drop));
                    changed = true;
                    break;
                }
            }
            if (changed) break;
        }
        if (changed) continue;

        for (0..columns) |drop| {
            if (!active_columns[drop]) continue;
            const drop_cover = columnCoverage(&masks, &active_rows, rows, drop);
            for (0..columns) |keep| {
                if (!active_columns[keep] or keep == drop) continue;
                const keep_cover = columnCoverage(&masks, &active_rows, rows, keep);
                const exclusive_rows = drop_cover & ~keep_cover;
                if (drop_cover & keep_cover == 0 or exclusive_rows == 0) continue;
                var replacement_columns: u64 = 0;
                var feasible = true;
                for (0..rows) |row| {
                    if (exclusive_rows & (@as(u64, 1) << @intCast(row)) == 0) continue;
                    var minimum_column: ?usize = null;
                    for (0..columns) |candidate| {
                        if (!active_columns[candidate] or masks[row] & (@as(u64, 1) << @intCast(candidate)) == 0) continue;
                        if (minimum_column == null or weights[candidate] < weights[minimum_column.?] or
                            (weights[candidate] == weights[minimum_column.?] and candidate < minimum_column.?))
                            minimum_column = candidate;
                    }
                    if (minimum_column) |candidate| replacement_columns |= @as(u64, 1) << @intCast(candidate)
                    else { feasible = false; break; }
                }
                var replacement_cost = weights[keep];
                for (0..columns) |candidate| {
                    if (replacement_columns & (@as(u64, 1) << @intCast(candidate)) != 0)
                        replacement_cost += weights[candidate];
                }
                if (feasible and weights[drop] >= replacement_cost) {
                    active_columns[drop] = false;
                    for (0..rows) |row| masks[row] &= ~(@as(u64, 1) << @intCast(drop));
                    changed = true;
                    break;
                }
            }
            if (changed) break;
        }
        if (!changed) break;
    }

    var row_ids: [MAX_ROWS]usize = @splat(0);
    var column_ids: [MAX_COLUMNS]usize = @splat(0);
    var reduced_masks: [MAX_ROWS]u64 = @splat(0);
    var row_count: usize = 0;
    var column_count: usize = 0;
    for (0..rows) |row| if (active_rows[row]) { row_ids[row_count] = row; row_count += 1; };
    for (0..columns) |column| if (active_columns[column]) { column_ids[column_count] = column; column_count += 1; };
    for (0..row_count) |i| {
        for (0..column_count) |j| {
            if (masks[row_ids[i]] & (@as(u64, 1) << @intCast(column_ids[j])) != 0)
                reduced_masks[i] |= @as(u64, 1) << @intCast(j);
        }
    }
    const words = 2 + 2 * row_count + 2 * column_count;
    const bytes = 8 * words;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    var cursor: usize = 0;
    storeI64Le(&staged, 8 * cursor, @intCast(row_count)); cursor += 1;
    storeI64Le(&staged, 8 * cursor, @intCast(column_count)); cursor += 1;
    for (0..row_count) |i| { storeI64Le(&staged, 8 * cursor, @intCast(row_ids[i])); cursor += 1; }
    for (0..column_count) |i| { storeI64Le(&staged, 8 * cursor, @intCast(column_ids[i])); cursor += 1; }
    for (0..column_count) |i| { storeI64Le(&staged, 8 * cursor, weights[column_ids[i]]); cursor += 1; }
    for (0..row_count) |i| { storeI64Le(&staged, 8 * cursor, @intCast(reduced_masks[i])); cursor += 1; }
    if (output == null or capacity < bytes) return -2;
    for (0..bytes) |byte| output.?[byte] = staged[byte];
    return @intCast(bytes);
}
