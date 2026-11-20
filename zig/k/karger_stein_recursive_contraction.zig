// Independently authored draft; not compiled or run.
const Graph = struct {
    n: usize, m: usize, q: usize, position: usize = 0,
    left: [32]usize = @splat(0), right: [32]usize = @splat(0),
    tape: [64]i64 = @splat(0),
};
fn root(parent: *const [12]usize, vertex: usize) usize {
    var current = vertex;
    while (parent[current] != current) current = parent[current];
    return current;
}
fn solve(g: *Graph, parent: *const [12]usize, components: usize) i64 {
    if (components <= 6) {
        var index: [12]usize = @splat(0);
        var count: usize = 0;
        for (0..g.n) |i| if (parent[i] == i) { index[i] = count; count += 1; };
        var best: i64 = @intCast(g.m + 1);
        const limit = (@as(usize, 1) << @as(u6, @intCast(components-1))) - 1;
        for (0..limit) |mask| {
            const side = (mask << 1) | 1;
            var cut: i64 = 0;
            for (0..g.m) |e| {
                const a: u6 = @intCast(index[root(parent, g.left[e])]);
                const b: u6 = @intCast(index[root(parent, g.right[e])]);
                if ((side >> a) & 1 != (side >> b) & 1) cut += 1;
            }
            best = @min(best, cut);
        }
        return best;
    }
    const targets = [_]usize{0,0,0,0,0,0,0,6,7,8,9,9,10};
    var best: i64 = @intCast(g.m + 1);
    for (0..2) |_| {
        var next = parent.*;
        var remaining = components;
        while (remaining > targets[components]) : (remaining -= 1) {
            var live: i64 = 0;
            for (0..g.m) |e| if (root(&next, g.left[e]) != root(&next, g.right[e])) { live += 1; };
            if (g.position >= g.q) return -1;
            var rank = g.tape[g.position]; g.position += 1;
            if (rank < 0 or rank >= live) return -1;
            for (0..g.m) |e| {
                const a = root(&next, g.left[e]); const b = root(&next, g.right[e]);
                if (a == b) continue;
                if (rank == 0) { next[b] = a; break; }
                rank -= 1;
            }
        }
        const value = solve(g, &next, targets[components]);
        if (value < 0) return -1;
        best = @min(best, value);
    }
    return best;
}
export fn karger_stein_recursive_contraction(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 3 or length > 132) return -1;
    if (input[0] < 2 or input[0] > 12 or input[1] < 1 or input[1] > 32 or input[2] < 0 or input[2] > 64) return -1;
    var g = Graph{ .n = @intCast(input[0]), .m = @intCast(input[1]), .q = @intCast(input[2]) };
    if (length != 3 + 2*g.m + g.q) return -1;
    var parent: [12]usize = @splat(0);
    for (0..g.n) |i| parent[i] = i;
    for (0..g.m) |i| {
        const u = input[3+2*i]; const v = input[4+2*i];
        if (u < 0 or v < 0 or u >= input[0] or v >= input[0] or u == v) return -1;
        g.left[i] = @intCast(u); g.right[i] = @intCast(v);
        const a = root(&parent, g.left[i]); const b = root(&parent, g.right[i]);
        parent[b] = a;
    }
    const initial = root(&parent, 0);
    for (1..g.n) |i| if (root(&parent, i) != initial) { return -1; };
    for (0..g.n) |i| parent[i] = i;
    for (0..g.q) |i| g.tape[i] = input[3+2*g.m+i];
    const value = solve(&g, &parent, g.n);
    if (value < 0 or g.position != g.q) return -1;
    return value;
}
