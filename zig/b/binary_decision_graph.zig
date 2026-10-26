fn put_i64(out: [*c]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[at * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn binary_decision_graph(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 65) return -1;
    const nv = input[0];
    if (nv < 1 or nv > 6 or length != 1 + (@as(usize, 1) << @intCast(nv))) return -1;
    const n: usize = @intCast(nv);
    const count = @as(usize, 1) << @intCast(nv);
    var ids = [_]i64{0} ** 64;
    var next = [_]i64{0} ** 64;
    var vars = [_]i64{0} ** 63;
    var lows = [_]i64{0} ** 63;
    var highs = [_]i64{0} ** 63;
    for (0..count) |i| {
        if (input[i + 1] != 0 and input[i + 1] != 1) return -1;
        ids[i] = input[i + 1];
    }
    var nodes: usize = 0;
    var current_count = count;
    for (0..n) |step| {
        const variable = n - 1 - step;
        const next_count = current_count / 2;
        for (0..next_count) |p| {
            const lo = ids[2 * p];
            const hi = ids[2 * p + 1];
            if (lo == hi) { next[p] = lo; continue; }
            var found = nodes;
            var j = nodes;
            while (j > 0) {
                j -= 1;
                if (@as(usize, @intCast(vars[j])) != variable) break;
                if (lows[j] == lo and highs[j] == hi) { found = j; break; }
            }
            if (found == nodes) {
                vars[nodes] = @intCast(variable); lows[nodes] = lo; highs[nodes] = hi;
                next[p] = @intCast(2 + nodes); nodes += 1;
            } else next[p] = @intCast(2 + found);
        }
        for (0..next_count) |p| ids[p] = next[p];
        current_count = next_count;
    }
    const bytes = 8 * (2 + 3 * nodes);
    if (output == null or capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, @intCast(nodes));
    for (0..nodes) |i| {
        put_i64(output, 2 + 3 * i, vars[i]);
        put_i64(output, 3 + 3 * i, lows[i]);
        put_i64(output, 4 + 3 * i, highs[i]);
    }
    return @intCast(bytes);
}
