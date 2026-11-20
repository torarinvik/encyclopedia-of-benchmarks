const max_n: usize = 16;
const max_m: usize = 120;
const max_parseable_input: usize = 243;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

// Clean-room bounded edge-peeling truss decomposition.
export fn k_truss_edge_peeling_decomposition(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_parseable_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 120 or
        length != 2 + 2 * @as(usize, @intCast(m64)) or length > 242) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var edge_index = [_][max_n]i16{[_]i16{-1} ** max_n} ** max_n;
    var edge_u = [_]usize{0} ** max_m;
    var edge_v = [_]usize{0} ** max_m;
    var support = [_]i32{0} ** max_m;
    var alive = [_]bool{false} ** max_m;
    var trussness = [_]i64{0} ** max_m;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        edge_index[u][v] = @intCast(edge);
        edge_index[v][u] = @intCast(edge);
        edge_u[edge] = u;
        edge_v[edge] = v;
        alive[edge] = true;
    }
    for (0..n) |u| {
        for (u + 1..n) |v| {
            for (v + 1..n) |w| {
                if (adjacent[u][v] and adjacent[u][w] and adjacent[v][w]) {
                    support[@intCast(edge_index[u][v])] += 1;
                    support[@intCast(edge_index[u][w])] += 1;
                    support[@intCast(edge_index[v][w])] += 1;
                }
            }
        }
    }
    const output_bytes = 8 * m;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var remaining = m;
    var level: i32 = 0;
    while (remaining > 0) {
        var selected: usize = max_m;
        for (0..m) |edge| {
            if (alive[edge] and (selected == max_m or support[edge] < support[selected])) selected = edge;
        }
        level = @max(level, support[selected]);
        trussness[selected] = level + 2;
        alive[selected] = false;
        remaining -= 1;
        const u = edge_u[selected];
        const v = edge_v[selected];
        for (0..n) |w| {
            if (w == u or w == v or !adjacent[u][w] or !adjacent[v][w]) continue;
            const first: usize = @intCast(edge_index[u][w]);
            const second: usize = @intCast(edge_index[v][w]);
            if (alive[first] and alive[second]) {
                if (support[first] > level) support[first] -= 1;
                if (support[second] > level) support[second] -= 1;
            }
        }
    }
    for (0..m) |edge| storeI64Le(output, 8 * edge, trussness[edge]);
    return @intCast(output_bytes);
}
