const CW_P: usize = 6;
const CW_L: usize = 8;
const CW_T: usize = 64;
const CW_NODES: usize = 33;
const CW_INPUT: usize = 105;

fn isSuffix(v: usize, u: usize, depth: [CW_NODES]usize,
            path: [CW_NODES * CW_L]i64) bool {
    if (depth[v] >= depth[u]) return false;
    const offset = depth[u] - depth[v];
    for (0..depth[v]) |i| {
        if (path[v * CW_L + i] != path[u * CW_L + offset + i]) return false;
    }
    return true;
}

export fn commentz_walter(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > CW_INPUT) return -1;
    const raw_p = values[0];
    const raw_n = values[1];
    if (raw_p < 1 or raw_p > CW_P or raw_n < 0 or raw_n > CW_T) return -1;
    const p: usize = @intCast(raw_p);
    const n: usize = @intCast(raw_n);
    if (length < 2 + p) return -1;
    var lens: [CW_P]usize = @splat(0);
    var total: usize = 0;
    var shortest: usize = CW_L + 1;
    for (0..p) |i| {
        const raw = values[2 + i];
        if (raw < 1 or raw > CW_L) return -1;
        lens[i] = @intCast(raw);
        total += lens[i];
        shortest = @min(shortest, lens[i]);
    }
    if (total > 32 or length != 2 + p + total + n) return -1;
    var patterns: [CW_P * CW_L]i64 = @splat(0);
    var text: [CW_T]i64 = @splat(0);
    var at: usize = 2 + p;
    for (0..p) |i| {
        for (0..lens[i]) |j| {
            const symbol = values[at]; at += 1;
            if (symbol < 1 or symbol > 4) return -1;
            patterns[i * CW_L + j] = symbol;
        }
        for (0..i) |prior| {
            if (lens[prior] != lens[i]) continue;
            var same = true;
            for (0..lens[i]) |j| {
                if (patterns[prior * CW_L + j] != patterns[i * CW_L + j]) same = false;
            }
            if (same) return -1;
        }
    }
    for (0..n) |i| {
        const symbol = values[at]; at += 1;
        if (symbol < 1 or symbol > 4) return -1;
        text[i] = symbol;
    }

    var child: [CW_NODES * 5]usize = @splat(0);
    var parent: [CW_NODES]usize = @splat(0);
    var label: [CW_NODES]usize = @splat(0);
    var depth: [CW_NODES]usize = @splat(0);
    var path: [CW_NODES * CW_L]i64 = @splat(0);
    var terminal: [CW_NODES]bool = @splat(false);
    var nodes: usize = 1;
    for (0..p) |i| {
        var v: usize = 0;
        var j = lens[i];
        while (j > 0) {
            j -= 1;
            const symbol: usize = @intCast(patterns[i * CW_L + j]);
            var encoded = child[v * 5 + symbol];
            if (encoded == 0) {
                const u = nodes; nodes += 1;
                child[v * 5 + symbol] = u + 1;
                parent[u] = v;
                label[u] = symbol;
                depth[u] = depth[v] + 1;
                for (0..depth[v]) |k| path[u * CW_L + k] = path[v * CW_L + k];
                path[u * CW_L + depth[v]] = @intCast(symbol);
                encoded = u + 1;
            }
            v = encoded - 1;
        }
        terminal[v] = true;
    }

    var shift1: [CW_NODES]usize = @splat(0);
    var shift2: [CW_NODES]usize = @splat(0);
    var bad: [5]usize = @splat(0);
    for (0..nodes) |v| { shift1[v] = shortest; shift2[v] = shortest; }
    shift1[0] = 1;
    for (0..5) |a| bad[a] = shortest + 1;
    for (1..nodes) |v| {
        bad[label[v]] = @min(bad[label[v]], depth[v]);
        shift2[v] = shift2[parent[v]];
        for (1..nodes) |u| {
            if (isSuffix(v, u, depth, path)) {
                const delta = depth[u] - depth[v];
                shift1[v] = @min(shift1[v], delta);
                if (terminal[u]) shift2[v] = @min(shift2[v], delta);
            }
        }
    }

    var matches: i64 = 0;
    var position: usize = shortest - 1;
    while (position < n) {
        var v: usize = 0;
        var i: isize = @intCast(position);
        while (i >= 0) {
            const symbol: usize = @intCast(text[@intCast(i)]);
            const encoded = child[v * 5 + symbol];
            if (encoded == 0) break;
            v = encoded - 1;
            i -= 1;
            if (terminal[v]) matches += 1;
        }
        const symbol: usize = if (i >= 0) @intCast(text[@intCast(i)]) else 0;
        const char_shift = if (symbol == 0) shortest + 1 else bad[symbol];
        const char_delta: isize = @as(isize, @intCast(char_shift)) - @as(isize, @intCast(depth[v])) - 1;
        const delta = @min(shift2[v], @max(shift1[v], if (char_delta > 0) @as(usize, @intCast(char_delta)) else 0));
        position += delta;
    }
    return matches;
}
