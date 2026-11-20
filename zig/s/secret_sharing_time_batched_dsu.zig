const MAX_N: usize = 16;

fn findRoot(parent: *[MAX_N]usize, node_start: usize) usize {
    var node = node_start;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn joinSets(parent: *[MAX_N]usize, size: *[MAX_N]usize, left: usize, right: usize) void {
    var a = findRoot(parent, left);
    var b = findRoot(parent, right);
    if (a == b) return;
    if (size[a] < size[b]) { const swap = a; a = b; b = swap; }
    parent[b] = a;
    size[a] += size[b];
}

export fn secret_sharing_time_batched_dsu(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 64) return -1;
    const input = input_opt.?;
    const n_value, first_value, m_value = .{ input[0], input[1], input[2] };
    if (n_value < 2 or n_value > 16 or first_value < 1 or first_value >= n_value
        or m_value < 0 or m_value > 20) return -1;
    const n: usize = @intCast(n_value);
    const first: usize = @intCast(first_value);
    const m: usize = @intCast(m_value);
    if (length != 3 + 3 * m) return -1;
    var parent: [MAX_N]usize = @splat(0);
    var size: [MAX_N]usize = @splat(1);
    for (0..n) |i| parent[i] = i;
    for (0..m) |i| {
        const u, const v, const time = .{ input[3 + 3*i], input[4 + 3*i], input[5 + 3*i] };
        if (u < 0 or u >= n_value or v < 0 or v >= n_value or u == v or time < 1 or time > 20)
            return -1;
    }
    joinSets(&parent, &size, 0, first);
    for (1..21) |time| {
        var touched: [MAX_N]bool = @splat(false);
        for (0..m) |i| {
            const u: usize = @intCast(input[3 + 3*i]);
            const v: usize = @intCast(input[4 + 3*i]);
            if (input[5 + 3*i] == @as(i64, @intCast(time))) {
                joinSets(&parent, &size, u, v);
                touched[u] = true;
                touched[v] = true;
            }
        }
        const known_root = findRoot(&parent, 0);
        for (0..n) |node| {
            if (touched[node] and findRoot(&parent, node) != known_root) {
                parent[node] = node;
                size[node] = 1;
            }
        }
    }
    const known_root = findRoot(&parent, 0);
    var result: i64 = 0;
    for (0..n) |node| {
        if (findRoot(&parent, node) == known_root) result |= @as(i64, 1) << @intCast(node);
    }
    return result;
}
