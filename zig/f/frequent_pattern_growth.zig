const Context = struct { minimum: i64, order: [8]usize, result: i64 = 0 };

fn grow(ctx: *Context, masks: []const i64, weights: []const i64, rank_limit: usize) void {
    var rank = rank_limit;
    while (rank > 0) {
        rank -= 1;
        const bit = @as(i64, 1) << @as(u6, @intCast(ctx.order[rank]));
        var support: i64 = 0;
        for (masks, weights) |mask, weight| { if ((mask & bit) != 0) support += weight; }
        if (support < ctx.minimum) continue;
        ctx.result += 1;
        var ancestor: i64 = 0;
        for (0..rank) |r| { ancestor |= @as(i64, 1) << @as(u6, @intCast(ctx.order[r])); }
        var next_masks: [64]i64 = undefined;
        var next_weights: [64]i64 = undefined;
        var next_len: usize = 0;
        for (masks, weights) |mask, weight| {
            if ((mask & bit) != 0) { next_masks[next_len] = mask & ancestor; next_weights[next_len] = weight; next_len += 1; }
        }
        grow(ctx, next_masks[0..next_len], next_weights[0..next_len], rank);
    }
}

export fn frequent_pattern_growth(a: [*c]const i64, n: usize) i64 {
    if (a == null or n < 3 or n > 67) return -1;
    const rows = a[0]; const items = a[1]; const minimum = a[2];
    if (rows < 1 or rows > 64 or items < 1 or items > 8 or minimum < 1 or minimum > rows or n != 3 + @as(usize, @intCast(rows))) return -1;
    const limit: i64 = @as(i64, 1) << @as(u6, @intCast(items));
    for (0..@as(usize, @intCast(rows))) |r| { const mask = a[3 + r]; if (mask < 0 or mask >= limit) return -1; }
    var masks: [64]i64 = undefined;
    var weights: [64]i64 = undefined;
    var support: [8]i64 = @splat(0);
    const row_count: usize = @intCast(rows);
    const item_count: usize = @intCast(items);
    for (0..row_count) |r| {
        masks[r] = a[3 + r]; weights[r] = 1;
        for (0..item_count) |item| { if ((masks[r] & (@as(i64, 1) << @as(u6, @intCast(item)))) != 0) support[item] += 1; }
    }
    var ctx = Context{ .minimum = minimum, .order = undefined };
    for (0..item_count) |i| ctx.order[i] = i;
    for (1..item_count) |i| {
        const value = ctx.order[i]; var j = i;
        while (j > 0 and (support[ctx.order[j - 1]] < support[value] or (support[ctx.order[j - 1]] == support[value] and ctx.order[j - 1] > value))) { ctx.order[j] = ctx.order[j - 1]; j -= 1; }
        ctx.order[j] = value;
    }
    grow(&ctx, masks[0..row_count], weights[0..row_count], item_count);
    return ctx.result;
}
