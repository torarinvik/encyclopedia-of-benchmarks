const max_items: usize = 8;
const max_rows: usize = 16;
const max_words: usize = 513;

fn support(rows: *const [max_rows]i64, row_count: usize, mask: i64) usize {
    var count: usize = 0;
    for (0..row_count) |row| {
        if ((rows.*[row] & mask) == mask) count += 1;
    }
    return count;
}

fn closure(rows: *const [max_rows]i64, row_count: usize, item_count: usize, mask: i64) i64 {
    var common = (@as(i64, 1) << @intCast(item_count)) - 1;
    for (0..row_count) |row| {
        const transaction = rows.*[row];
        if ((transaction & mask) == mask) common &= transaction;
    }
    return common;
}

fn coreIndex(rows: *const [max_rows]i64, row_count: usize, item_count: usize,
        mask: i64, pattern_support: usize) usize {
    for (0..item_count) |item| {
        const prefix_mask = (@as(i64, 1) << @intCast(item + 1)) - 1;
        if (support(rows, row_count, mask & prefix_mask) == pattern_support) return item;
    }
    return item_count - 1;
}

fn putI64Le(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn lcm_ppc_closed_itemset_enumeration(input_opt: ?[*]const i64,
        length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > 3 + max_rows) return -1;
    const input = input_opt.?;
    const item_value = input[0];
    const row_value = input[1];
    const minimum = input[2];
    if (item_value < 1 or item_value > @as(i64, @intCast(max_items)) or row_value < 1 or
        row_value > @as(i64, @intCast(max_rows)) or
        minimum < 1 or minimum > row_value or length != 3 + @as(usize, @intCast(row_value))) return -1;
    const item_count: usize = @intCast(item_value);
    const row_count: usize = @intCast(row_value);
    const limit = @as(i64, 1) << @intCast(item_count);
    var rows = [_]i64{0} ** max_rows;
    for (0..row_count) |row| {
        const mask = input[3 + row];
        if (mask < 0 or mask >= limit) return -1;
        rows[row] = mask;
    }

    var words = [_]i64{0} ** max_words;
    var stack_mask = [_]i64{0} ** (max_items + 1);
    var stack_support = [_]usize{0} ** (max_items + 1);
    var stack_core = [_]i64{0} ** (max_items + 1);
    var next_item = [_]i64{0} ** (max_items + 1);
    var entered = [_]bool{false} ** (max_items + 1);
    stack_mask[0] = closure(&rows, row_count, item_count, 0);
    stack_support[0] = row_count;
    stack_core[0] = -1;
    var depth: usize = 0;
    var record_count: usize = 0;
    var active = true;
    while (active) {
        if (!entered[depth]) {
            words[1 + 2 * record_count] = stack_mask[depth];
            words[2 + 2 * record_count] = @intCast(stack_support[depth]);
            record_count += 1;
            entered[depth] = true;
            next_item[depth] = stack_core[depth] + 1;
        }
        if (next_item[depth] >= item_value) {
            entered[depth] = false;
            if (depth == 0) {
                active = false;
            } else {
                depth -= 1;
            }
            continue;
        }

        const item: usize = @intCast(next_item[depth]);
        next_item[depth] += 1;
        const bit = @as(i64, 1) << @intCast(item);
        const parent_mask = stack_mask[depth];
        if ((parent_mask & bit) != 0) continue;
        const extended = parent_mask | bit;
        const child_support = support(&rows, row_count, extended);
        if (child_support < @as(usize, @intCast(minimum))) continue;
        const child = closure(&rows, row_count, item_count, extended);
        const lower_prefix = bit - 1;
        if ((parent_mask & lower_prefix) != (child & lower_prefix)) continue;
        depth += 1;
        stack_mask[depth] = child;
        stack_support[depth] = child_support;
        stack_core[depth] = @intCast(coreIndex(&rows, row_count, item_count, child, child_support));
        entered[depth] = false;
    }

    words[0] = @intCast(record_count);
    const output_bytes = 8 * (1 + 2 * record_count);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..1 + 2 * record_count) |word| putI64Le(output, word, words[word]);
    return @intCast(output_bytes);
}
