const MAX_ROWS: usize = 6;
const MAX_COLUMNS: usize = 8;
const MAX_INPUT: usize = 17;
const MAX_STACK: usize = 32;

fn storeI64Le(output: []u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

fn intervalCover(
    left: [MAX_ROWS]usize,
    right: [MAX_ROWS]usize,
    count: usize,
    weights: [MAX_COLUMNS]i64,
    columns: usize,
    out_cost: *i64,
    out_mask: *i64,
) bool {
    if (count == 0) {
        out_cost.* = 0;
        out_mask.* = 0;
        return true;
    }
    var minimum_right = right[0];
    var maximum_left = left[0];
    for (1..count) |i| {
        minimum_right = @min(minimum_right, right[i]);
        maximum_left = @max(maximum_left, left[i]);
    }
    var costs: [MAX_COLUMNS]i64 = @splat(1_000_000);
    var masks: [MAX_COLUMNS]i64 = @splat(0);
    for (0..columns) |point| {
        if (point <= minimum_right) {
            costs[point] = weights[point];
            masks[point] = @as(i64, 1) << @intCast(point);
        }
        for (0..point) |previous| {
            if (costs[previous] == 1_000_000) continue;
            var blocked = false;
            for (0..count) |i| {
                if (previous < left[i] and right[i] < point) {
                    blocked = true;
                    break;
                }
            }
            if (blocked) continue;
            const candidate_cost = costs[previous] + weights[point];
            const candidate_mask = masks[previous] | (@as(i64, 1) << @intCast(point));
            if (candidate_cost < costs[point] or
                (candidate_cost == costs[point] and candidate_mask < masks[point])) {
                costs[point] = candidate_cost;
                masks[point] = candidate_mask;
            }
        }
    }
    var best_cost: i64 = 1_000_000;
    var best_mask: i64 = 0;
    for (maximum_left..columns) |point| {
        if (costs[point] < best_cost or
            (costs[point] == best_cost and costs[point] != 1_000_000 and masks[point] < best_mask)) {
            best_cost = costs[point];
            best_mask = masks[point];
        }
    }
    if (best_cost == 1_000_000) return false;
    out_cost.* = best_cost;
    out_mask.* = best_mask;
    return true;
}

export fn ruf_schobel_set_cover(
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
    var row_masks: [MAX_ROWS]u64 = @splat(0);
    var block_left: [MAX_ROWS][MAX_COLUMNS]usize = undefined;
    var block_right: [MAX_ROWS][MAX_COLUMNS]usize = undefined;
    var block_count: [MAX_ROWS]usize = @splat(0);
    for (0..rows) |row| {
        const raw = values[2 + columns + row];
        if (raw < 0 or (@as(u64, @intCast(raw)) & ~allowed) != 0) return -1;
        row_masks[row] = @intCast(raw);
        var column: usize = 0;
        while (column < columns) {
            if ((row_masks[row] & (@as(u64, 1) << @intCast(column))) == 0) {
                column += 1;
                continue;
            }
            const block = block_count[row];
            block_left[row][block] = column;
            while (column + 1 < columns and
                (row_masks[row] & (@as(u64, 1) << @intCast(column + 1))) != 0) column += 1;
            block_right[row][block] = column;
            block_count[row] += 1;
            column += 1;
        }
    }
    for (0..rows) |row| {
        if (row_masks[row] == 0) {
            if (output == null or capacity < 8) return -2;
            var staged: [8]u8 = undefined;
            storeI64Le(staged[0..], -1);
            @memcpy(output.?[0..8], staged[0..]);
            return 8;
        }
    }

    var best_cost: i64 = 1_000_000;
    var stack: [MAX_STACK][MAX_ROWS]i8 = undefined;
    for (0..MAX_STACK) |slot| {
        for (0..MAX_ROWS) |row| stack[slot][row] = -1;
    }
    var stack_size: usize = 1;
    while (stack_size > 0) {
        stack_size -= 1;
        const fixed = stack[stack_size];
        var left: [MAX_ROWS]usize = @splat(0);
        var right: [MAX_ROWS]usize = @splat(0);
        var count: usize = 0;
        for (0..rows) |row| {
            if (block_count[row] == 1 or fixed[row] >= 0) {
                const block: usize = if (block_count[row] == 1) 0 else @intCast(fixed[row]);
                left[count] = block_left[row][block];
                right[count] = block_right[row][block];
                count += 1;
            }
        }
        var lower_cost: i64 = 0;
        var lower_mask: i64 = 0;
        if (!intervalCover(left, right, count, weights, columns, &lower_cost, &lower_mask)) continue;
        var extra_left: [MAX_ROWS]usize = @splat(0);
        var extra_right: [MAX_ROWS]usize = @splat(0);
        var extra_count: usize = 0;
        for (0..rows) |row| {
            if ((row_masks[row] & @as(u64, @intCast(lower_mask))) != 0) continue;
            var chosen: usize = 0;
            var chosen_cost: i64 = 1_000_000;
            for (0..block_count[row]) |block| {
                var cheapest: i64 = 1_000_000;
                for (block_left[row][block]..block_right[row][block] + 1) |column| {
                    cheapest = @min(cheapest, weights[column]);
                }
                if (cheapest < chosen_cost) {
                    chosen = block;
                    chosen_cost = cheapest;
                }
            }
            extra_left[extra_count] = block_left[row][chosen];
            extra_right[extra_count] = block_right[row][chosen];
            extra_count += 1;
        }
        var extra_cost: i64 = 0;
        var extra_mask: i64 = 0;
        if (!intervalCover(extra_left, extra_right, extra_count, weights, columns, &extra_cost, &extra_mask)) continue;
        const candidate_mask = lower_mask | extra_mask;
        var candidate_cost: i64 = 0;
        for (0..columns) |column| {
            if ((candidate_mask & (@as(i64, 1) << @intCast(column))) != 0) candidate_cost += weights[column];
        }
        best_cost = @min(best_cost, candidate_cost);
        if (best_cost <= lower_cost) continue;
        var branch: ?usize = null;
        for (0..rows) |row| {
            if (block_count[row] > 1 and fixed[row] < 0) { branch = row; break; }
        }
        if (branch == null) continue;
        var block = block_count[branch.?];
        while (block > 0) {
            block -= 1;
            for (0..rows) |row| stack[stack_size][row] = fixed[row];
            stack[stack_size][branch.?] = @intCast(block);
            stack_size += 1;
        }
    }
    const result: i64 = if (best_cost == 1_000_000) -1 else best_cost;
    if (output == null or capacity < 8) return -2;
    var staged: [8]u8 = undefined;
    storeI64Le(staged[0..], result);
    @memcpy(output.?[0..8], staged[0..]);
    return 8;
}
