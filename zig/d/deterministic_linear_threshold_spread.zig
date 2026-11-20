const MAX_N: usize = 8;
const MAX_M: usize = 24;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn deterministic_linear_threshold_spread(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 92) return -1;
    const values = input.?;
    const n_raw = values[0]; const m_raw = values[1]; const s_raw = values[2];
    if (n_raw < 1 or n_raw > 8 or m_raw < 0 or m_raw > 24 or s_raw < 0 or s_raw > n_raw) return -1;
    const n: usize = @intCast(n_raw); const m: usize = @intCast(m_raw); const seed_count: usize = @intCast(s_raw);
    const edge_offset = 3 + seed_count; const threshold_offset = edge_offset + 3 * m;
    if (length != threshold_offset + n) return -1;
    var seeded: [MAX_N]bool = @splat(false);
    var seen: [MAX_N * MAX_N]bool = @splat(false);
    var head: [MAX_N]i64 = @splat(-1);
    var edge_to: [MAX_M]i64 = @splat(0);
    var edge_weight: [MAX_M]i64 = @splat(0);
    var edge_next: [MAX_M]i64 = @splat(-1);
    var incoming: [MAX_N]i64 = @splat(0);
    var threshold: [MAX_N]i64 = @splat(0);
    var activation_round: [MAX_N]i64 = @splat(-1);
    var accumulated: [MAX_N]i64 = @splat(0);
    for (0..seed_count) |i| {
        const seed = values[3 + i];
        if (seed < 0 or seed >= n_raw or seeded[@intCast(seed)]) return -1;
        seeded[@intCast(seed)] = true;
        activation_round[@intCast(seed)] = 0;
    }
    for (0..m) |i| {
        const u = values[edge_offset + 3 * i]; const v = values[edge_offset + 3 * i + 1]; const w = values[edge_offset + 3 * i + 2];
        if (u < 0 or u >= n_raw or v < 0 or v >= n_raw or u == v or w < 0 or w > 16) return -1;
        const ui: usize = @intCast(u); const vi: usize = @intCast(v);
        const slot = ui * MAX_N + vi;
        if (seen[slot]) return -1;
        seen[slot] = true;
        incoming[vi] += w;
        if (incoming[vi] > 16) return -1;
        edge_to[i] = v; edge_weight[i] = w; edge_next[i] = head[ui]; head[ui] = @intCast(i);
    }
    for (0..n) |v| {
        threshold[v] = values[threshold_offset + v];
        if (threshold[v] < 1 or threshold[v] > 16) return -1;
    }
    const output_bytes = 8 * (n + 2);
    if (output == null or capacity < output_bytes) return -2;
    var frontier: [MAX_N]usize = @splat(0);
    var following: [MAX_N]usize = @splat(0);
    var frontier_count: usize = 0;
    for (0..n) |v| { if (seeded[v]) { frontier[frontier_count] = v; frontier_count += 1; } }
    var waves: i64 = 0;
    while (frontier_count != 0) {
        var following_count: usize = 0;
        for (frontier[0..frontier_count]) |source| {
            var edge = head[source];
            while (edge >= 0) : (edge = edge_next[@intCast(edge)]) {
                const e: usize = @intCast(edge); const target: usize = @intCast(edge_to[e]);
                if (activation_round[target] >= 0) continue;
                accumulated[target] += edge_weight[e];
                if (accumulated[target] >= threshold[target]) {
                    activation_round[target] = waves + 1;
                    following[following_count] = target; following_count += 1;
                }
            }
        }
        frontier_count = following_count;
        for (0..following_count) |i| frontier[i] = following[i];
        if (following_count != 0) waves += 1;
    }
    const result = output.?;
    store_i64_le(result, 0, n_raw); store_i64_le(result, 8, waves);
    for (0..n) |v| store_i64_le(result, 8 * (v + 2), activation_round[v]);
    return @intCast(output_bytes);
}
