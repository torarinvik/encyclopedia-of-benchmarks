const MAX_N: usize = 9;
const MAX_CELLS: usize = 81;
const MAX_INPUT_LENGTH: usize = 111;
const INF: i64 = 1 << 60;

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn minimum_weight_cycle_floyd(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 3 or n_value > @as(i64, @intCast(MAX_N)) or m_value < 0
            or m_value > n_value * (n_value - 1) / 2) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 3 * m) return -1;

    var edge: [MAX_CELLS]i64 = @splat(INF);
    var dist: [MAX_CELLS]i64 = @splat(INF);
    for (0..n) |i| edge[i * MAX_N + i] = 0;
    for (0..m) |e| {
        const offset = 2 + 3 * e;
        const u_value = input[offset];
        const v_value = input[offset + 1];
        const weight = input[offset + 2];
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
                or u_value == v_value or weight < 1 or weight > 1000) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (edge[u * MAX_N + v] != INF) return -1;
        edge[u * MAX_N + v] = weight;
        edge[v * MAX_N + u] = weight;
    }
    if (output_opt == null or capacity < 8) return -2;
    for (0..n) |i| {
        for (0..n) |j| dist[i * MAX_N + j] = edge[i * MAX_N + j];
    }

    var best: i64 = INF;
    for (0..n) |k| {
        for (0..k) |i| {
            if (edge[i * MAX_N + k] == INF) continue;
            var j = i + 1;
            while (j < k) : (j += 1) {
                if (edge[k * MAX_N + j] == INF or dist[i * MAX_N + j] == INF) continue;
                const candidate = edge[i * MAX_N + k] + edge[k * MAX_N + j] + dist[i * MAX_N + j];
                if (candidate < best) best = candidate;
            }
        }
        for (0..n) |i| {
            if (dist[i * MAX_N + k] == INF) continue;
            for (0..n) |j| {
                if (dist[k * MAX_N + j] == INF) continue;
                const candidate = dist[i * MAX_N + k] + dist[k * MAX_N + j];
                if (candidate < dist[i * MAX_N + j]) dist[i * MAX_N + j] = candidate;
            }
        }
    }
    storeI64Le(output_opt.?, if (best == INF) -1 else best);
    return 8;
}
