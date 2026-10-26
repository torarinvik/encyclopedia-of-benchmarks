const std = @import("std");
const max_n: usize = 8;
const max_input: usize = 65;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn metric_tsp_tree_doubling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 1 or n64 > 8 or length != 1 + @as(usize, @intCast(n64 * n64))) return -1;
    const n: usize = @intCast(n64);
    var d: [max_n][max_n]i64 = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    for (0..n) |u| for (0..n) |v| {
        const w = input[1 + u * n + v];
        if (w < 0 or w > 10000 or (u == v and w != 0)) return -1;
        d[u][v] = w;
    };
    for (0..n) |u| for (u + 1..n) |v| if (d[u][v] != d[v][u]) return -1;
    for (0..n) |u| for (0..n) |v| for (0..n) |k| if (d[u][v] > d[u][k] + d[k][v]) return -1;
    const output_bytes = 8 * (n + 2);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var processed: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var tree: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var parent: [max_n]usize = [_]usize{0} ** max_n;
    for (0..n) |i| parent[i] = i;
    var accepted: usize = 0;
    const edge_count = n * (n - 1) / 2;
    for (0..edge_count) |_| {
        if (accepted + 1 >= n) break;
        var bu: usize = 0;
        var bv: usize = 0;
        var bw: i64 = std.math.maxInt(i64);
        for (0..n) |u| for (u + 1..n) |v| {
            if (!processed[u][v] and d[u][v] < bw) { bu = u; bv = v; bw = d[u][v]; }
        };
        processed[bu][bv] = true;
        var ru = bu;
        var rv = bv;
        while (parent[ru] != ru) ru = parent[ru];
        while (parent[rv] != rv) rv = parent[rv];
        if (ru != rv) {
            parent[rv] = ru;
            tree[bu][bv] = true;
            tree[bv][bu] = true;
            accepted += 1;
        }
    }
    var stack: [max_n]usize = [_]usize{0} ** max_n;
    var order: [max_n]usize = [_]usize{0} ** max_n;
    var visited: [max_n]bool = [_]bool{false} ** max_n;
    var top: usize = 1;
    var count: usize = 0;
    while (top > 0) {
        top -= 1;
        const v = stack[top];
        if (visited[v]) continue;
        visited[v] = true;
        order[count] = v;
        count += 1;
        var rev = n;
        while (rev > 0) {
            rev -= 1;
            if (tree[v][rev] and !visited[rev]) { stack[top] = rev; top += 1; }
        }
    }
    var cost: i64 = 0;
    for (0..n - 1) |i| cost += d[order[i]][order[i + 1]];
    cost += d[order[n - 1]][0];
    storeI64LE(output, 0, cost);
    for (0..n) |i| storeI64LE(output, 8 * (i + 1), @intCast(order[i]));
    storeI64LE(output, 8 * (n + 1), 0);
    return @intCast(output_bytes);
}
