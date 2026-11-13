fn root(parent: *const [8]usize, vertex: usize) usize {
    var current = vertex;
    while (parent[current] != current) current = parent[current];
    return current;
}

export fn karger_contraction_trial(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 57) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > 8 or input[1] < 1 or input[1] > 24) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 2 * m + n - 2) return -1;
    var u: [24]usize = @splat(0);
    var v: [24]usize = @splat(0);
    var parent: [8]usize = @splat(0);
    for (0..n) |i| parent[i] = i;
    for (0..m) |i| {
        const a = input[2 + 2 * i];
        const b = input[3 + 2 * i];
        if (a < 0 or b < 0 or a >= input[0] or b >= input[0] or a == b) return -1;
        u[i] = @intCast(a);
        v[i] = @intCast(b);
        const left = root(&parent, u[i]);
        const right = root(&parent, v[i]);
        parent[left] = right;
    }
    const initial = root(&parent, 0);
    for (1..n) |i| {
        if (root(&parent, i) != initial) return -1;
    }
    for (0..n) |i| parent[i] = i;
    for (0..n - 2) |step| {
        var live: i64 = 0;
        for (0..m) |i| {
            if (root(&parent, u[i]) != root(&parent, v[i])) live += 1;
        }
        var rank = input[2 + 2 * m + step];
        if (rank < 0 or rank >= live) return -1;
        for (0..m) |i| {
            const left = root(&parent, u[i]);
            const right = root(&parent, v[i]);
            if (left == right) continue;
            if (rank == 0) { parent[left] = right; break; }
            rank -= 1;
        }
    }
    var cut: i64 = 0;
    for (0..m) |i| {
        if (root(&parent, u[i]) != root(&parent, v[i])) cut += 1;
    }
    return cut;
}
