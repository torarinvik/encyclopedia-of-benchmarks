// Clean-room bounded GBBS widest-path profile; see package LICENSE.txt.
const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 195;
const source_infinity: i64 = 2_147_483_647;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_ss_widest_path(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const source64 = input[2];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or source64 < 0 or source64 >= n64
        or length != 3 + 3 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const source: usize = @intCast(source64);
    var edge_from: [max_m]usize = [_]usize{0} ** max_m;
    var edge_to: [max_m]usize = [_]usize{0} ** max_m;
    var edge_capacity: [max_m]i64 = [_]i64{0} ** max_m;
    for (0..m) |edge| {
        const from = input[3 + 3 * edge];
        const to = input[4 + 3 * edge];
        const edge_width = input[5 + 3 * edge];
        if (from < 0 or from >= n64 or to < 0 or to >= n64 or edge_width < 1 or edge_width > 32) return -1;
        edge_from[edge] = @intCast(from);
        edge_to[edge] = @intCast(to);
        edge_capacity[edge] = edge_width;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var width: [max_n]i64 = [_]i64{0} ** max_n;
    var settled: [max_n]bool = [_]bool{false} ** max_n;
    width[source] = source_infinity;
    for (0..n) |_| {
        var u: usize = n;
        for (0..n) |vertex| {
            if (!settled[vertex] and (u == n or width[vertex] > width[u])) u = vertex;
        }
        if (u == n or width[u] == 0) break;
        settled[u] = true;
        for (0..m) |edge| {
            if (edge_from[edge] != u) continue;
            const v = edge_to[edge];
            if (settled[v]) continue;
            const candidate = @min(width[u], edge_capacity[edge]);
            if (candidate > width[v]) width[v] = candidate;
        }
    }
    for (0..n) |vertex| storeI64LE(output, 8 * vertex, width[vertex]);
    return @intCast(output_bytes);
}
