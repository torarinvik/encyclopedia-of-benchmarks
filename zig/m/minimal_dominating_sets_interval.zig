const std = @import("std");
const MAX_N: usize = 12;

fn intersects(s: *const [MAX_N]i64, e: *const [MAX_N]i64, a: usize, b: usize) bool {
    return s[a] <= e[b] and s[b] <= e[a];
}

export fn minimal_dominating_sets_interval(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null) return -1;
    if (length < 3 or length > 25) return -1;
    const values = input.?;
    const n0 = values[0];
    if (n0 < 1 or n0 > 12 or length != 1 + 2 * @as(usize, @intCast(n0))) return -1;
    const n: usize = @intCast(n0);
    var s = [_]i64{0} ** MAX_N; var e = [_]i64{0} ** MAX_N;
    var min_end: i64 = std.math.maxInt(i64); var max_start: i64 = std.math.minInt(i64);
    for (0..n) |i| {
        s[i] = values[1 + 2 * i]; e[i] = values[2 + 2 * i];
        if (s[i] < -100 or s[i] > 100 or e[i] < -100 or e[i] > 100 or s[i] >= e[i]) return -1;
        if (i > 0 and s[i - 1] >= s[i]) return -1;
        min_end = @min(min_end, e[i]); max_start = @max(max_start, s[i]);
        for (0..i) |j| if (s[i] == s[j] or s[i] == e[j] or e[i] == s[j] or e[i] == e[j]) return -1;
    }
    if (output == null or capacity < 8) return -2;
    const bytes = output.?;
    var has_next = [_]bool{false} ** MAX_N; var ncs = [_]i64{0} ** MAX_N; var nce = [_]i64{0} ** MAX_N;
    var p_single = [_]i64{std.math.maxInt(i64)} ** MAX_N;
    for (0..n) |i| for (0..n) |z| {
        if (intersects(&s, &e, i, z)) p_single[i] = @min(p_single[i], e[z]);
        if (s[z] > e[i]) { if (!has_next[i] or s[z] < ncs[i]) ncs[i] = s[z]; if (!has_next[i] or e[z] < nce[i]) nce[i] = e[z]; has_next[i] = true; }
    };
    var valid = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var p_pair = [_][MAX_N]i64{[_]i64{std.math.maxInt(i64)} ** MAX_N} ** MAX_N;
    for (0..n) |i| for (i + 1..n) |j| {
        for (0..n) |z| if (intersects(&s, &e, j, z) and !intersects(&s, &e, i, z)) p_pair[i][j] = @min(p_pair[i][j], e[z]);
        valid[i][j] = has_next[i] and p_single[i] < s[j] and s[j] <= nce[i] and e[j] >= ncs[i];
    };
    var ways = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_N;
    for (1..n) |j| for (0..j) |i| {
        if (!valid[i][j]) continue;
        if (s[i] <= min_end) ways[i][j] += 1;
        for (j + 1..n) |k| if (valid[j][k] and p_pair[i][j] < s[k] and s[k] <= nce[j]) ways[j][k] += ways[i][j];
    };
    var count: i64 = 0;
    for (0..n) |i| if (s[i] <= min_end and e[i] >= max_start) count += 1;
    for (0..n) |i| for (i + 1..n) |j| if (e[j] >= max_start) count += ways[i][j];
    const bits: u64 = @intCast(count);
    for (0..8) |b| bytes[b] = @truncate(bits >> (8 * b));
    return 8;
}
