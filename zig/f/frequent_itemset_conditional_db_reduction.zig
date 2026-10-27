const MAX_INPUT: usize = 69;
const MAX_OUTPUT: usize = 1032;

fn putU64(output: [*c]u8, word: usize, value: u64) void {
    for (0..8) |byte| output[word * 8 + byte] = @truncate(value >> @intCast(8 * byte));
}

export fn frequent_itemset_conditional_db_reduction(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 6 or length > MAX_INPUT) return -1;
    const n0 = input[0]; const rows0 = input[1]; const minimum = input[2];
    const tail = input[3]; const prefix0 = input[4];
    if (n0 < 1 or n0 > 8 or rows0 < 1 or rows0 > 64 or minimum < 1 or minimum > rows0 or length != 5 + @as(usize, @intCast(rows0))) return -1;
    if (tail < -1 or tail >= n0 or prefix0 < 0) return -1;
    const n: usize = @intCast(n0); const row_count: usize = @intCast(rows0);
    const limit = @as(u64, 1) << @as(u6, @intCast(n));
    const prefix: u64 = @intCast(prefix0);
    if (prefix >= limit or (tail == -1 and prefix != 0) or
        (tail >= 0 and (((prefix >> @as(u6, @intCast(tail))) & 1) == 0 or (prefix >> @as(u6, @intCast(tail + 1))) != 0))) return -1;
    var selected = [_]u64{0} ** 64;
    var support = [_]u64{0} ** 8;
    var selected_count: usize = 0;
    for (0..row_count) |row| {
        const row0 = input[5 + row];
        if (row0 < 0 or @as(u64, @intCast(row0)) >= limit) return -1;
        const mask: u64 = @intCast(row0);
        if ((mask & prefix) != prefix) continue;
        selected[selected_count] = mask;
        selected_count += 1;
        var item: usize = @intCast(tail + 1);
        while (item < n) : (item += 1) {
            if ((mask & (@as(u64, 1) << @as(u6, @intCast(item)))) != 0) support[item] += 1;
        }
    }
    if (selected_count < @as(usize, @intCast(minimum))) return -1;
    var keep: u64 = 0;
    if (tail >= 0) keep = @as(u64, 1) << @as(u6, @intCast(tail));
    var item: usize = @intCast(tail + 1);
    while (item < n) : (item += 1) {
        if (support[item] >= @as(u64, @intCast(minimum))) keep |= @as(u64, 1) << @as(u6, @intCast(item));
    }
    const below: u64 = if (tail > 0) (@as(u64, 1) << @as(u6, @intCast(tail))) - 1 else 0;
    var masks = [_]u64{0} ** 64;
    var counts = [_]u64{0} ** 64;
    var distinct: usize = 0;
    for (0..selected_count) |row| {
        const reduced = selected[row] & ~below & keep;
        var at: usize = 0;
        while (at < distinct and masks[at] != reduced) : (at += 1) {}
        if (at == distinct) { masks[distinct] = reduced; distinct += 1; }
        counts[at] += 1;
    }
    for (1..distinct) |i| {
        const saved_mask = masks[i]; const saved_count = counts[i];
        var j = i;
        while (j > 0 and masks[j - 1] > saved_mask) : (j -= 1) { masks[j] = masks[j - 1]; counts[j] = counts[j - 1]; }
        masks[j] = saved_mask; counts[j] = saved_count;
    }
    const word_count = 1 + 2 * distinct; const bytes = 8 * word_count;
    if (bytes > MAX_OUTPUT) return -1;
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    putU64(output, 0, distinct);
    for (0..distinct) |i| { putU64(output, 1 + 2 * i, masks[i]); putU64(output, 2 + 2 * i, counts[i]); }
    return @intCast(bytes);
}
