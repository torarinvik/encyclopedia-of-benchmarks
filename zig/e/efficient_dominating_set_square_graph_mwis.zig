/// Efficient domination via weighted independent set on the square graph.
const MAX_VERTICES: usize = 12;

fn bitCount(bits0: u16) i32 {
    var bits = bits0;
    var count: i32 = 0;
    while (bits != 0) : (bits &= bits - 1) { count += 1; }
    return count;
}

fn weightedMis(square: *const [MAX_VERTICES]u16, weights: *const [MAX_VERTICES]i32,
               remaining: u16, current: i32, best: *i32) void {
    var upper = current;
    for (0..MAX_VERTICES) |v| {
        if ((remaining & (@as(u16, 1) << @intCast(v))) != 0) upper += weights[v];
    }
    if (upper <= best.*) return;
    if (remaining == 0) { best.* = current; return; }
    var branch: usize = 0;
    var branch_degree: i32 = -1;
    for (0..MAX_VERTICES) |v| {
        const bit = @as(u16, 1) << @intCast(v);
        if ((remaining & bit) == 0) continue;
        const degree = bitCount(square[v] & remaining);
        if (degree > branch_degree) { branch = v; branch_degree = degree; }
    }
    const bit = @as(u16, 1) << @intCast(branch);
    weightedMis(square, weights, remaining & ~bit & ~square[branch], current + weights[branch], best);
    weightedMis(square, weights, remaining & ~bit, current, best);
}

pub export fn efficient_dominating_set_square_graph_mwis(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 135) return -1;
    const n64, m64 = input[0], input[1];
    if (n64 < 1 or n64 > 12 or m64 < 0 or m64 > n64 * (n64 - 1) / 2) return -1;
    if (length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacency: [MAX_VERTICES]u16 = @splat(0);
    for (0..m) |e| {
        const u64, v64 = input[2 + 2 * e], input[3 + 2 * e];
        if (u64 < 0 or u64 >= v64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        const bit = @as(u16, 1) << @intCast(v);
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit;
        adjacency[v] |= @as(u16, 1) << @intCast(u);
    }
    var square: [MAX_VERTICES]u16 = @splat(0);
    var weights: [MAX_VERTICES]i32 = @splat(0);
    for (0..n) |v| {
        square[v] = adjacency[v];
        for (0..n) |u| if ((adjacency[v] & (@as(u16, 1) << @intCast(u))) != 0) {
            square[v] |= adjacency[u];
        };
        square[v] &= ~(@as(u16, 1) << @intCast(v));
        weights[v] = bitCount(adjacency[v]) + 1;
    }
    var best: i32 = 0;
    weightedMis(&square, &weights, (@as(u16, 1) << @intCast(n)) - 1, 0, &best);
    return if (best == n64) 1 else 0;
}
