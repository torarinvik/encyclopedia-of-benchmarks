const Context = struct {
    minimum: i64,
    words: [511]i64 = [_]i64{0} ** 511,
    records: usize = 0,
};

fn enumerate(ctx: *Context, rows: []const i64, item_count: usize, start_item: usize, prefix: i64) void {
    for (start_item..item_count) |item| {
        const bit: i64 = @as(i64, 1) << @intCast(item);
        var projected: [16]i64 = undefined;
        var projected_count: usize = 0;
        for (rows) |row| {
            if ((row & bit) != 0) { projected[projected_count] = row; projected_count += 1; }
        }
        if (@as(i64, @intCast(projected_count)) < ctx.minimum) continue;
        const mask = prefix | bit;
        const at = 1 + 2 * ctx.records;
        ctx.words[at] = mask;
        ctx.words[at + 1] = @intCast(projected_count);
        ctx.records += 1;
        enumerate(ctx, projected[0..projected_count], item_count, item + 1, mask);
    }
}

fn put_i64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[word * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn frequent_itemset_backtrack(input: [*c]const i64, length: usize,
                                     output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 19) return -1;
    const item_count0 = input[0]; const row_count0 = input[1]; const minimum = input[2];
    if (item_count0 < 1 or item_count0 > 8 or row_count0 < 1 or row_count0 > 16 or
        minimum < 1 or minimum > row_count0 or length != 3 + @as(usize, @intCast(row_count0))) return -1;
    const item_count: usize = @intCast(item_count0); const row_count: usize = @intCast(row_count0);
    const limit: i64 = @as(i64, 1) << @intCast(item_count);
    var rows: [16]i64 = undefined;
    for (0..row_count) |i| {
        const mask = input[3 + i];
        if (mask < 0 or mask >= limit) return -1;
        rows[i] = mask;
    }
    var ctx = Context{ .minimum = minimum };
    enumerate(&ctx, rows[0..row_count], item_count, 0, 0);
    ctx.words[0] = @intCast(ctx.records);
    const word_count = 1 + 2 * ctx.records;
    const bytes = word_count * 8;
    if (output == null or capacity < bytes) return -2;
    for (0..word_count) |i| put_i64(output, i, ctx.words[i]);
    return @intCast(bytes);
}
