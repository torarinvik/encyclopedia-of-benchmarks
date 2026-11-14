pub export fn xor_leaf_tree_traversal(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or input[0] < 1 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (input[1] < 0 or input[1] >= input[0] or length != 2 * n) return -1;
    const root: usize = @intCast(input[1]);
    var degree: [64]i32 = @splat(0);
    var edge_xor: [64]usize = @splat(0);
    var parents: [64]i64 = @splat(-1);
    var order: [64]i64 = @splat(0);
    var dsu: [64]usize = @splat(0);
    var ranks: [64]u8 = @splat(0);
    var a: [63]usize = @splat(0);
    var b: [63]usize = @splat(0);
    for (0..n) |i| dsu[i] = i;
    for (0..n - 1) |e| {
        const ur = input[2 + 2 * e];
        const vr = input[3 + 2 * e];
        if (ur < 0 or ur >= input[0] or vr < 0 or vr >= input[0] or ur == vr) return -1;
        const u: usize = @intCast(ur);
        const v: usize = @intCast(vr);
        var x = u; var y = v;
        while (dsu[x] != x) { dsu[x] = dsu[dsu[x]]; x = dsu[x]; }
        while (dsu[y] != y) { dsu[y] = dsu[dsu[y]]; y = dsu[y]; }
        if (x == y) return -1;
        if (ranks[x] < ranks[y]) { dsu[x] = y; } else {
            dsu[y] = x;
            if (ranks[x] == ranks[y]) ranks[x] += 1;
        }
        a[e] = u; b[e] = v;
        degree[u] += 1; degree[v] += 1; edge_xor[u] ^= e; edge_xor[v] ^= e;
    }
    degree[root] = 0;
    var used: usize = 0;
    for (0..n) |start| {
        var v = start;
        while (degree[v] == 1) {
            const e = edge_xor[v];
            const next = a[e] ^ b[e] ^ v;
            parents[v] = @intCast(e); order[used] = @intCast(v); used += 1;
            degree[v] = 0; degree[next] -= 1; edge_xor[next] ^= e; v = next;
        }
    }
    order[used] = @intCast(root); used += 1;
    if (used != n) return -1;
    if (output == null or capacity < 16 * n) return -2;
    for (0..2 * n) |i| {
        const value = if (i < n) parents[i] else order[i - n];
        const bits: u64 = @bitCast(value);
        for (0..8) |byte| output[8 * i + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
    }
    return @intCast(16 * n);
}
