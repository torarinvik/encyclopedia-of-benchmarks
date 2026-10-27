const std = @import("std");
const N: usize = 8;
const M: usize = 256;

fn put(out: [*]u8, pos: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[pos + b] = @truncate(bits >> (8 * b));
}

export fn metric_tsp_christofides(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 65) return -1;
    const values = input.?; const n64 = values[0];
    if (n64 < 1 or n64 > N or length != 1 + @as(usize, @intCast(n64 * n64))) return -1;
    const n: usize = @intCast(n64); var d = [_][N]i64{[_]i64{0} ** N} ** N;
    for (0..n) |i| for (0..n) |j| {
        const w = values[1 + i * n + j];
        if (w < 0 or w > 10000 or (i == j and w != 0)) return -1;
        d[i][j] = w;
    };
    for (0..n) |i| for (0..n) |j| {
        if (d[i][j] != d[j][i]) return -1;
        for (0..n) |k| if (d[i][j] > d[i][k] + d[k][j]) return -1;
    };
    const bytes = 8 * (n + 2);
    if (output == null or capacity < bytes) return -2;
    const out = output.?;
    var used = [_][N]bool{[_]bool{false} ** N} ** N;
    var tree = [_][N]bool{[_]bool{false} ** N} ** N;
    var parent = [_]usize{0} ** N; for (0..n) |i| parent[i] = i;
    var accepted: usize = 0;
    while (accepted < n - 1) {
        var bu: usize = 0; var bv: usize = 0; var bw: i64 = std.math.maxInt(i64);
        for (0..n) |u| for (u + 1..n) |v| {
            if (!used[u][v] and (d[u][v] < bw or (d[u][v] == bw and (u < bu or (u == bu and v < bv))))) { bu = u; bv = v; bw = d[u][v]; }
        };
        used[bu][bv] = true; var a = bu; var b = bv;
        while (parent[a] != a) a = parent[a]; while (parent[b] != b) b = parent[b];
        if (a != b) { parent[b] = a; tree[bu][bv] = true; tree[bv][bu] = true; accepted += 1; }
    }
    var odd = [_]usize{0} ** N; var on: usize = 0;
    for (0..n) |i| { var deg: usize = 0; for (0..n) |j| { if (tree[i][j]) deg += 1; } if (deg % 2 == 1) { odd[on] = i; on += 1; } }
    const full: usize = (@as(usize, 1) << @intCast(on)) - 1;
    var dp = [_]i64{std.math.maxInt(i64)} ** M; var pick = [_]usize{N} ** M; dp[0] = 0;
    for (1..full + 1) |mask| {
        const i: usize = @ctz(mask); const rest = mask ^ (@as(usize, 1) << @intCast(i));
        for (i + 1..on) |j| if ((rest & (@as(usize, 1) << @intCast(j))) != 0) {
            const tail = rest ^ (@as(usize, 1) << @intCast(j)); const value = dp[tail] + d[odd[i]][odd[j]];
            if (value < dp[mask]) { dp[mask] = value; pick[mask] = j; }
        };
    }
    var multi = [_][N]u8{[_]u8{0} ** N} ** N;
    for (0..n) |i| for (0..n) |j| { if (tree[i][j]) multi[i][j] = 1; };
    var mask = full;
    while (mask != 0) { const i: usize = @ctz(mask); const j = pick[mask]; const u = odd[i]; const v = odd[j]; multi[u][v] += 1; multi[v][u] += 1; mask ^= (@as(usize, 1) << @intCast(i)) | (@as(usize, 1) << @intCast(j)); }
    var stack = [_]usize{0} ** 32; var top: usize = 1; var rev = [_]usize{0} ** 32; var rc: usize = 0;
    while (top > 0) { const v = stack[top - 1]; var w: ?usize = null; for (0..n) |x| { if (multi[v][x] > 0) { w = x; break; } }
        if (w) |x| { multi[v][x] -= 1; multi[x][v] -= 1; stack[top] = x; top += 1; } else { top -= 1; rev[rc] = stack[top]; rc += 1; }
    }
    var seen = [_]bool{false} ** N; var order = [_]usize{0} ** N; var count: usize = 0;
    var r = rc; while (r > 0) { r -= 1; const v = rev[r]; if (!seen[v]) { seen[v] = true; order[count] = v; count += 1; } }
    var cost: i64 = 0; for (0..n - 1) |i| cost += d[order[i]][order[i + 1]]; cost += d[order[n - 1]][0];
    put(out, 0, cost); for (0..n) |i| put(out, 8 * (i + 1), @intCast(order[i])); put(out, 8 * (n + 1), 0);
    return @intCast(bytes);
}
