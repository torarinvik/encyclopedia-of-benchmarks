// Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt.
const std = @import("std");
const N: usize = 16;
const M: usize = 64;
const MAX_INPUT: usize = 2 + 2 * M + 2;
const INVALID: f64 = -1.0e300;

export fn gbbs_bkv12_densest_subgraph(input_opt: ?[*]const i64, length: usize) f64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return INVALID;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64
        or length != 2 + 2 * @as(usize, @intCast(m64))) return INVALID;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var adjacent = [_][N]bool{[_]bool{false} ** N} ** N;
    var degree = [_]i64{0} ** N;
    var edge_u = [_]usize{0} ** M; var edge_v = [_]usize{0} ** M;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge]; const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return INVALID;
        const u: usize = @intCast(u64); const v: usize = @intCast(v64);
        if (adjacent[u][v]) return INVALID;
        adjacent[u][v] = true; adjacent[v][u] = true;
        degree[u] += 1; degree[v] += 1; edge_u[edge] = u; edge_v[edge] = v;
    }
    var alive = [_]bool{false} ** N;
    for (0..n) |vertex| alive[vertex] = true;
    var remaining = n;
    var best: f64 = 0.0;
    while (remaining > 0) {
        var total: i64 = 0;
        for (0..n) |vertex| { if (alive[vertex]) total += degree[vertex]; }
        const density = @as(f64, @floatFromInt(total)) / @as(f64, @floatFromInt(remaining));
        if (density > best) best = density;
        var removed = [_]bool{false} ** N;
        var count: usize = 0;
        for (0..n) |vertex| {
            if (alive[vertex] and 1000 * degree[vertex] * @as(i64, @intCast(remaining)) <= 1001 * total) {
                removed[vertex] = true; count += 1;
            }
        }
        if (count == 0) return INVALID;
        for (0..n) |vertex| { if (removed[vertex]) alive[vertex] = false; }
        remaining -= count;
        for (0..m) |edge| {
            const u = edge_u[edge]; const v = edge_v[edge];
            if (removed[u] and alive[v]) degree[v] -= 1;
            if (removed[v] and alive[u]) degree[u] -= 1;
        }
    }
    return if (std.math.isFinite(best)) best else INVALID;
}
