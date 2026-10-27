const MAX_ROWS: usize = 8;
const MAX_COLUMNS: usize = 10;
const MAX_OUTPUT_BYTES: usize = 80;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn almost_c1p_set_cover_enumeration(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > 21) return -1;
    const input = input_opt.?;
    const rows_raw = input[0];
    const columns_raw = input[1];
    if (rows_raw < 1 or rows_raw > @as(i64, MAX_ROWS) or columns_raw < 1 or
            columns_raw > @as(i64, MAX_COLUMNS) or length != 2 + @as(usize, @intCast(rows_raw + columns_raw))) return -1;
    const rows: usize = @intCast(rows_raw);
    const columns: usize = @intCast(columns_raw);
    var weights: [MAX_COLUMNS]i64 = @splat(0);
    for (0..columns) |column| {
        const weight = input[2 + column];
        if (weight < 1 or weight > 20) return -1;
        weights[column] = weight;
    }
    const valid_mask = (@as(u64, 1) << @intCast(columns)) - 1;
    var row_masks: [MAX_ROWS]u64 = @splat(0);
    for (0..rows) |row| {
        const raw_mask = input[2 + columns + row];
        if (raw_mask < 0 or (@as(u64, @intCast(raw_mask)) & ~valid_mask) != 0) return -1;
        row_masks[row] = @intCast(raw_mask);
    }

    const state_count = @as(usize, 1) << @intCast(columns);
    var feasible: [1 << MAX_COLUMNS]bool = @splat(false);
    feasible[0] = true;
    for (0..rows) |row| {
        const cover_mask = row_masks[row];
        for (0..state_count) |selected| {
            if (!feasible[selected] or (@as(u64, @intCast(selected)) & cover_mask) != 0) continue;
            feasible[selected] = false;
            for (0..columns) |column| {
                const bit = @as(usize, 1) << @intCast(column);
                if ((cover_mask & @as(u64, @intCast(bit))) != 0) feasible[selected | bit] = true;
            }
        }
    }

    var best_found = false;
    var best_mask: u64 = 0;
    var best_cost: i64 = 0;
    for (0..state_count) |selected| {
        if (!feasible[selected]) continue;
        var cost: i64 = 0;
        for (0..columns) |column| {
            if ((@as(u64, @intCast(selected)) & (@as(u64, 1) << @intCast(column))) != 0) cost += weights[column];
        }
        const mask: u64 = @intCast(selected);
        if (!best_found or cost < best_cost or (cost == best_cost and mask < best_mask)) {
            best_found = true;
            best_mask = mask;
            best_cost = cost;
        }
    }
    var selected_count: usize = 0;
    if (best_found) {
        for (0..columns) |column| if ((best_mask & (@as(u64, 1) << @intCast(column))) != 0) { selected_count += 1; };
    }
    const output_bytes = if (best_found) 8 * (selected_count + 2) else 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    if (best_found) {
        store_i64_le(&staged, 0, @intCast(selected_count));
        var cursor: usize = 1;
        for (0..columns) |column| {
            if ((best_mask & (@as(u64, 1) << @intCast(column))) != 0) {
                store_i64_le(&staged, 8 * cursor, @intCast(column));
                cursor += 1;
            }
        }
        store_i64_le(&staged, 8 * cursor, best_cost);
    } else {
        store_i64_le(&staged, 0, -1);
    }
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
