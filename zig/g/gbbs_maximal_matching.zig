const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 2 + 3 * max_m;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_maximal_matching(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or
        length != 2 + 3 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var rank_seen: [max_m]bool = [_]bool{false} ** max_m;
    var order: [max_m]usize = [_]usize{0} ** max_m;
    var adjacency: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    const edge_start = 2 + m;
    for (0..m) |edge| {
        const rank64 = input[2 + edge];
        if (rank64 < 0 or rank64 >= m64) return -1;
        const rank: usize = @intCast(rank64);
        if (rank_seen[rank]) return -1;
        rank_seen[rank] = true;
        order[rank] = edge;
        const u64 = input[edge_start + 2 * edge];
        const v64 = input[edge_start + 2 * edge + 1];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    const output_bytes = 8 * m;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var matched: [max_n]bool = [_]bool{false} ** max_n;
    var selected: [max_m]i64 = [_]i64{0} ** max_m;
    var rank: usize = 0;
    while (rank < m) : (rank += 1) {
        const edge = order[rank];
        const u: usize = @intCast(input[edge_start + 2 * edge]);
        const v: usize = @intCast(input[edge_start + 2 * edge + 1]);
        if (!matched[u] and !matched[v]) {
            selected[edge] = 1;
            matched[u] = true;
            matched[v] = true;
        }
    }
    for (0..m) |edge| storeI64LE(output, 8 * edge, selected[edge]);
    return @intCast(output_bytes);
}
