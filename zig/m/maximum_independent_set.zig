/// Exact MIS by maximum-degree branching and a greedy clique-cover bound.
const MAX_N: usize = 22;
const MAX_INPUT: usize = 465;

fn popcount(bits: u64) i64 { return @intCast(@popCount(bits)); }

fn cliqueCoverBound(adjacency: *const [MAX_N]u64, remaining_input: u64) i64 {
    var remaining = remaining_input;
    var cliques: i64 = 0;
    while (remaining != 0) {
        cliques += 1;
        var candidates = remaining;
        while (candidates != 0) {
            const bit = candidates & (~candidates + 1);
            const vertex: usize = @intCast(@ctz(bit));
            remaining &= ~bit;
            candidates &= ~bit;
            candidates &= adjacency[vertex];
        }
    }
    return cliques;
}

fn searchMis(adjacency: *const [MAX_N]u64, remaining: u64, chosen: i64, best: *i64) void {
    if (remaining == 0) { best.* = @max(best.*, chosen); return; }
    if (chosen + popcount(remaining) <= best.*) return;
    if (chosen + cliqueCoverBound(adjacency, remaining) <= best.*) return;
    var vertices = remaining;
    var branch: usize = 0;
    var branch_degree: i64 = -1;
    while (vertices != 0) {
        const bit = vertices & (~vertices + 1);
        const vertex: usize = @intCast(@ctz(bit));
        const degree = popcount(adjacency[vertex] & remaining);
        if (degree > branch_degree) { branch = vertex; branch_degree = degree; }
        vertices &= ~bit;
    }
    const bit = @as(u64, 1) << @intCast(branch);
    searchMis(adjacency, remaining & ~bit & ~adjacency[branch], chosen + 1, best);
    searchMis(adjacency, remaining & ~bit, chosen, best);
}

export fn maximum_independent_set(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 0 or n64 > @as(i64, MAX_N)) return -1;
    const max_edges = n64 * (n64 - 1) / 2;
    if (m64 < 0 or m64 > max_edges or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    var adjacency = [_]u64{0} ** MAX_N;
    const edge_count: usize = @intCast(m64);
    for (0..edge_count) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 < 0 or u64 >= n64 or v64 >= n64 or u64 == v64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        const v_bit = @as(u64, 1) << @intCast(v);
        if ((adjacency[u] & v_bit) != 0) return -1;
        adjacency[u] |= v_bit;
        adjacency[v] |= @as(u64, 1) << @intCast(u);
    }
    var best: i64 = 0;
    const all_vertices = (@as(u64, 1) << @intCast(n64)) - 1;
    searchMis(&adjacency, all_vertices, 0, &best);
    return best;
}
