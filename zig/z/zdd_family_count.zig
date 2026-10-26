fn put_i64(out: [*c]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[at * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn zdd_family_count(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 34) return -1;
    const n0 = input[0]; const m0 = input[1];
    if (n0 < 1 or n0 > 6 or m0 < 0 or m0 > 32 or length != @as(usize, @intCast(m0)) + 2) return -1;
    const n: usize = @intCast(n0); const limit = @as(usize, 1) << @intCast(n0); const m: usize = @intCast(m0);
    var ids = [_]i64{0} ** 64; var next = [_]i64{0} ** 64;
    var vars = [_]i64{0} ** 63; var lows = [_]i64{0} ** 63; var highs = [_]i64{0} ** 63;
    var counts = [_]i64{0} ** 65; counts[1] = 1; var seen = [_]bool{false} ** 64;
    for (0..m) |i| {
        const mask = input[2 + i];
        if (mask < 0 or @as(usize, @intCast(mask)) >= limit or seen[@intCast(mask)]) return -1;
        seen[@intCast(mask)] = true; ids[@intCast(mask)] = 1;
    }
    var nodes: usize = 0; var current_count = limit;
    for (0..n) |variable| {
        const next_count = current_count / 2;
        for (0..next_count) |p| {
            const low = ids[2 * p]; const high = ids[2 * p + 1];
            if (high == 0) { next[p] = low; continue; }
            var found = nodes; var j = nodes;
            while (j > 0) {
                j -= 1;
                if (@as(usize, @intCast(vars[j])) != variable) break;
                if (lows[j] == low and highs[j] == high) { found = j; break; }
            }
            if (found == nodes) {
                vars[nodes] = @intCast(variable); lows[nodes] = low; highs[nodes] = high;
                counts[2 + nodes] = counts[@intCast(low)] + counts[@intCast(high)];
                next[p] = @intCast(2 + nodes); nodes += 1;
            } else next[p] = @intCast(2 + found);
        }
        for (0..next_count) |p| ids[p] = next[p]; current_count = next_count;
    }
    const bytes = 8 * (3 + 3 * nodes);
    if (output == null or capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, @intCast(nodes)); put_i64(output, 2, counts[@intCast(ids[0])]);
    for (0..nodes) |i| {
        put_i64(output, 3 + 3 * i, vars[i]); put_i64(output, 4 + 3 * i, lows[i]); put_i64(output, 5 + 3 * i, highs[i]);
    }
    return @intCast(bytes);
}
