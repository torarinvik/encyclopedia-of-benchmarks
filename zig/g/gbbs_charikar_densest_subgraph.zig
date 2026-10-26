// Clean-room bounded GBBS Charikar profile; see package LICENSE.txt.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

export fn gbbs_charikar_densest_subgraph(input_opt: ?[*]const i64, length: usize) f64 {
    if (input_opt == null or length < 2 or length > 2 + 2 * MAX_M) return INVALID_RESULT;
    const input = input_opt.?; const n64 = input[0]; const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or length != 2 + 2 * @as(usize, @intCast(m64))) return INVALID_RESULT;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var adjacent = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var degree = [_]i32{0} ** MAX_N;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge]; const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return INVALID_RESULT;
        const u: usize = @intCast(u64); const v: usize = @intCast(v64);
        if (adjacent[u][v]) return INVALID_RESULT;
        adjacent[u][v] = true; adjacent[v][u] = true; degree[u] += 1; degree[v] += 1;
    }
    var alive = [_]bool{false} ** MAX_N; var order = [_]usize{0} ** MAX_N; var position = [_]usize{0} ** MAX_N;
    for (0..n) |v| alive[v] = true;
    var used: usize = 0;
    while (used < n) {
        var level: i32 = MAX_M;
        for (0..n) |v| { if (alive[v] and degree[v] < level) level = degree[v]; }
        while (true) {
            var shell = [_]usize{0} ** MAX_N; var count: usize = 0;
            for (0..n) |v| { if (alive[v] and degree[v] == level) { shell[count] = v; count += 1; } }
            if (count == 0) break;
            for (0..count) |i| { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
            for (0..n) |v| { if (alive[v]) {
                var removed: i32 = 0;
                for (0..count) |i| { if (adjacent[v][shell[i]]) removed += 1; }
                degree[v] = @max(degree[v] - removed, level);
            } }
        }
    }
    for (0..n) |i| position[order[i]] = i;
    var best: f64 = 0.0;
    for (0..n) |start| {
        var edges: usize = 0;
        for (0..n) |u| { if (position[u] >= start) {
            var v = u + 1; while (v < n) : (v += 1) { if (position[v] >= start and adjacent[u][v]) edges += 1; }
        } }
        const score = 2.0 * @as(f64, @floatFromInt(edges)) / @as(f64, @floatFromInt(n - start));
        if (score > best) best = score;
    }
    return if (std.math.isFinite(best)) best else INVALID_RESULT;
}

const std = @import("std");
