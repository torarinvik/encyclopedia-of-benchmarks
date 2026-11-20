const MAX_N: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 10;

fn storeI64(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn havel_hakimi_graph_realization(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_N) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 1) return -1;
    var residual: [MAX_N]i64 = @splat(0);
    var active: [MAX_N]bool = @splat(false);
    for (0..n) |v| {
        const d = input[v + 1];
        if (d < 0 or d >= n_value) return -1;
        residual[v] = d; active[v] = true;
    }
    var left: [MAX_EDGES]i64 = @splat(0);
    var right: [MAX_EDGES]i64 = @splat(0);
    var edge_count: usize = 0;
    var graphical = true;
    while (graphical) {
        var hub: ?usize = null;
        for (0..n) |v| {
            if (active[v] and residual[v] > 0) {
                if (hub == null or residual[v] > residual[hub.?] or (residual[v] == residual[hub.?] and v < hub.?)) hub = v;
            }
        }
        if (hub == null) break;
        const h = hub.?;
        const d: usize = @intCast(residual[h]); residual[h] = 0; active[h] = false;
        var candidates: [MAX_N]usize = @splat(0);
        var count: usize = 0;
        for (0..n) |v| { if (active[v]) { candidates[count] = v; count += 1; } }
        var i: usize = 1;
        while (i < count) : (i += 1) {
            const value = candidates[i]; var j = i;
            while (j > 0 and (residual[candidates[j - 1]] < residual[value] or
                (residual[candidates[j - 1]] == residual[value] and candidates[j - 1] > value))) : (j -= 1) { candidates[j] = candidates[j - 1]; }
            candidates[j] = value;
        }
        if (d > count) { graphical = false; break; }
        for (candidates[0..d]) |v| {
            if (residual[v] == 0) { graphical = false; break; }
            residual[v] -= 1;
            left[edge_count] = @intCast(@min(h, v)); right[edge_count] = @intCast(@max(h, v)); edge_count += 1;
        }
    }
    var words: [2 + 2 * MAX_EDGES]i64 = @splat(0);
    var used: usize = 0;
    if (graphical) {
        words[0] = 1; words[1] = @intCast(edge_count); used = 2 + 2 * edge_count;
        for (0..edge_count) |index| { words[2 + 2 * index] = left[index]; words[3 + 2 * index] = right[index]; }
    } else { words[0] = 0; used = 1; }
    const byte_count = used * 8;
    if (output_opt == null or capacity < byte_count) return -2;
    const output = output_opt.?;
    for (0..used) |index| storeI64(output[0..byte_count], index * 8, words[index]);
    return @intCast(byte_count);
}
