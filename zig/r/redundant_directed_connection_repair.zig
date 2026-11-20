const MAX_N: usize = 16;

fn findRoot(parent: *[MAX_N]usize, node_start: usize) usize {
    var node = node_start;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

export fn redundant_directed_connection_repair(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length == 0 or length > 34) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 3 or n_value > 16) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 2 * n) return -1;
    var from: [MAX_N]usize = @splat(0);
    var to: [MAX_N]usize = @splat(0);
    for (0..n) |edge| {
        const u, const v = .{ input[1 + 2*edge], input[2 + 2*edge] };
        if (u < 0 or u >= n_value or v < 0 or v >= n_value or u == v) return -1;
        from[edge] = @intCast(u);
        to[edge] = @intCast(v);
        for (0..edge) |prior| if (from[prior] == from[edge] and to[prior] == to[edge]) { return -1; };
    }
    var incoming: [MAX_N]i64 = @splat(-1);
    var first_parent: i64 = -1;
    var second_parent: i64 = -1;
    for (0..n) |edge| {
        const child = to[edge];
        if (incoming[child] < 0) incoming[child] = @intCast(edge) else {
            first_parent = incoming[child];
            second_parent = @intCast(edge);
            break;
        }
    }
    var parent: [MAX_N]usize = @splat(0);
    var sizes: [MAX_N]usize = @splat(1);
    for (0..n) |node| parent[node] = node;
    var cycle_edge: i64 = -1;
    for (0..n) |edge| {
        if (@as(i64, @intCast(edge)) == second_parent) continue;
        var a = findRoot(&parent, from[edge]);
        var b = findRoot(&parent, to[edge]);
        if (a == b) { cycle_edge = @intCast(edge); break; }
        if (sizes[a] < sizes[b]) { const swap = a; a = b; b = swap; }
        parent[b] = a;
        sizes[a] += sizes[b];
    }
    if (cycle_edge >= 0) return if (second_parent >= 0) first_parent else cycle_edge;
    return second_parent;
}
