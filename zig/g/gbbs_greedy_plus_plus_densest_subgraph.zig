// Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt.
const std = @import("std");
const N: usize = 16;
const M: usize = 64;
const MAX_INPUT: usize = 2 + 2 * M + 2;
const INVALID: f64 = -1.0e300;

export fn gbbs_greedy_plus_plus_densest_subgraph(input_opt: ?[*]const i64, length: usize) f64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return INVALID;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 10 or n64 > 16 or m64 < 0 or m64 > 64
        or length != 2 + 2 * @as(usize, @intCast(m64))) return INVALID;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var adjacent = [_][N]bool{[_]bool{false} ** N} ** N;
    var load = [_]i64{0} ** N;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge]; const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return INVALID;
        const u: usize = @intCast(u64); const v: usize = @intCast(v64);
        if (adjacent[u][v]) return INVALID;
        adjacent[u][v] = true; adjacent[v][u] = true;
        load[u] += 1; load[v] += 1;
    }
    var best: f64 = 0.0;
    for (0..20) |_| {
        var degree = load;
        var alive = [_]bool{false} ** N;
        var order = [_]usize{0} ** N; var position = [_]usize{0} ** N;
        for (0..n) |v| alive[v] = true;
        var used: usize = 0;
        while (used < n) {
            var level: i64 = std.math.maxInt(i64);
            for (0..n) |v| { if (alive[v] and degree[v] < level) level = degree[v]; }
            var shell = [_]usize{0} ** N; var count: usize = 0;
            for (0..n) |v| { if (alive[v] and degree[v] == level) { shell[count] = v; count += 1; } }
            for (0..count) |i| { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
            for (0..n) |v| { if (alive[v]) {
                var removed: i64 = 0;
                for (0..count) |i| { if (adjacent[v][shell[i]]) removed += 1; }
                degree[v] = @max(degree[v] - removed, level);
            } }
        }
        for (0..n) |i| position[order[i]] = i;
        var density_above = [_]i64{0} ** N;
        for (0..n) |v| {
            var later: i64 = 0;
            for (0..n) |u| { if (adjacent[v][u] and position[u] > position[v]) later += 1; }
            density_above[position[v]] = 2 * later;
            load[v] += later;
        }
        var suffix_sum: i64 = 0;
        var index = n;
        while (index > 0) {
            index -= 1;
            suffix_sum += density_above[index];
            const score = @as(f64, @floatFromInt(suffix_sum)) / @as(f64, @floatFromInt(n - index));
            if (score > best) best = score;
        }
    }
    return if (std.math.isFinite(best)) best else INVALID;
}
