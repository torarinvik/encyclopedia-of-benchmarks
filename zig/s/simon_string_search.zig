const MAX_INPUT: usize = 274;

export fn simon_string_search(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 2 or length > MAX_INPUT) return -2;
    const values = values_opt.?;
    if (values[0] < 0 or values[0] > 256 or values[1] < 1 or values[1] > 16) return -2;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + n + m) return -2;
    for (0..n + m) |i| {
        if (values[2 + i] < 0 or values[2 + i] > 15) return -2;
    }
    const p = 2 + n;
    var head = [_]i32{-1} ** 16;
    var edge_target = [_]i32{0} ** 16;
    var edge_next = [_]i32{0} ** 16;
    var edge_count: usize = 0;
    var ell: i32 = -1;
    for (1..m) |i| {
        const k = ell;
        var cell: i32 = if (k < 0) -1 else head[@intCast(k)];
        ell = -1;
        if (values[p + @as(usize, @intCast(k + 1))] == values[p + i]) {
            ell = k + 1;
        } else {
            edge_target[edge_count] = k + 1;
            edge_next[edge_count] = head[i - 1];
            head[i - 1] = @intCast(edge_count);
            edge_count += 1;
        }
        while (cell >= 0) {
            const q = edge_target[@intCast(cell)];
            if (values[p + i] == values[p + @as(usize, @intCast(q))]) {
                ell = q;
            } else {
                edge_target[edge_count] = q;
                edge_next[edge_count] = head[i - 1];
                head[i - 1] = @intCast(edge_count);
                edge_count += 1;
            }
            cell = edge_next[@intCast(cell)];
        }
    }
    var state: i32 = -1;
    var matches: i64 = 0;
    for (0..n) |j| {
        const symbol = values[2 + j];
        if (state < @as(i32, @intCast(m)) - 1 and
            values[p + @as(usize, @intCast(state + 1))] == symbol) {
            state += 1;
        } else if (state >= 0) {
            var edge = head[@intCast(state)];
            state = -1;
            while (edge >= 0) {
                const q = edge_target[@intCast(edge)];
                if (values[p + @as(usize, @intCast(q))] == symbol) {
                    state = q;
                    break;
                }
                edge = edge_next[@intCast(edge)];
            }
        }
        if (state >= @as(i32, @intCast(m)) - 1) {
            matches += 1;
            state = ell;
        }
    }
    return matches;
}
