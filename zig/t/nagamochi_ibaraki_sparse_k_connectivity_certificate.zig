const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 60;

fn put(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn nagamochi_ibaraki_sparse_k_connectivity_certificate(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const k64 = input[2];
    if (n64 < 3 or n64 > 8 or m64 < 0 or m64 > 28 or k64 < 1 or k64 > 3
        or length != 3 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const k: usize = @intCast(k64);
    var u: [MAX_M]usize = @splat(0);
    var v: [MAX_M]usize = @splat(0);
    var incident: [MAX_N * MAX_N]usize = @splat(0);
    var degree: [MAX_N]usize = @splat(0);
    for (0..m) |e| {
        const a = input[3 + 2 * e];
        const b = input[4 + 2 * e];
        if (a < 0 or a >= b or b >= n64) return -1;
        u[e] = @intCast(a);
        v[e] = @intCast(b);
        for (0..e) |prior| if (u[prior] == u[e] and v[prior] == v[e]) return -1;
        incident[u[e] * MAX_N + degree[u[e]]] = e;
        degree[u[e]] += 1;
        incident[v[e] * MAX_N + degree[v[e]]] = e;
        degree[v[e]] += 1;
    }
    const bytes = 8 * (m + 1);
    if (output_opt == null or capacity < bytes) return -2;

    var rank: [MAX_N]usize = @splat(0);
    var layer: [MAX_M]usize = @splat(0);
    var scanned_vertex: [MAX_N]bool = @splat(false);
    var scanned_edge: [MAX_M]bool = @splat(false);
    for (0..n) |_| {
        var x = n;
        for (0..n) |vertex| {
            if (!scanned_vertex[vertex] and (x == n or rank[vertex] > rank[x])) x = vertex;
        }
        for (0..degree[x]) |slot| {
            const e = incident[x * MAX_N + slot];
            if (scanned_edge[e]) continue;
            const y = if (u[e] == x) v[e] else u[e];
            layer[e] = rank[y] + 1;
            if (rank[x] == rank[y]) rank[x] += 1;
            rank[y] += 1;
            scanned_edge[e] = true;
        }
        scanned_vertex[x] = true;
    }
    const output = output_opt.?;
    put(output, 0, @intCast(m));
    for (0..m) |e| put(output, 8 * (e + 1), @intCast(if (layer[e] <= k) layer[e] else 0));
    return @intCast(bytes);
}
