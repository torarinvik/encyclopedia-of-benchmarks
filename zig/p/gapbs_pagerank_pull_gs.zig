const std = @import("std");
const MAX_N: usize = 8;

export fn gapbs_pagerank_pull_gs(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 6 or length > 2 + MAX_N * MAX_N) return -1;
    const n64 = values[0];
    const iterations64 = values[1];
    if (n64 < 2 or n64 > MAX_N or iterations64 < 0 or iterations64 > 20) return -1;
    const n: usize = @intCast(n64);
    const iterations: usize = @intCast(iterations64);
    if (length != 2 + n * n) return -1;
    var matrix = [_]u8{0} ** (MAX_N * MAX_N);
    var outdegree = [_]usize{0} ** MAX_N;
    for (0..n) |row| {
        for (0..n) |column| {
            const value = values[2 + row * n + column];
            if ((value != 0 and value != 1) or (row == column and value != 0)) return -1;
            matrix[row * n + column] = @intCast(value);
            outdegree[row] += @intCast(value);
        }
        if (outdegree[row] == 0) return -1;
    }
    const damping: f32 = 0.85;
    const init_score: f32 = 1.0 / @as(f32, @floatFromInt(n));
    const base_score: f32 = (1.0 - damping) / @as(f32, @floatFromInt(n));
    var scores = [_]f32{0} ** MAX_N;
    var outgoing = [_]f32{0} ** MAX_N;
    for (0..n) |node| {
        scores[node] = init_score;
        outgoing[node] = init_score / @as(f32, @floatFromInt(outdegree[node]));
    }
    for (0..iterations) |_| {
        for (0..n) |target| {
            var incoming: f32 = 0.0;
            for (0..n) |source| {
                if (matrix[source * n + target] != 0) incoming += outgoing[source];
            }
            scores[target] = base_score + damping * incoming;
            outgoing[target] = scores[target] / @as(f32, @floatFromInt(outdegree[target]));
        }
    }
    var weighted: f64 = 0.0;
    for (0..n) |node| weighted += @as(f64, @floatFromInt(node + 1)) * @as(f64, scores[node]);
    return @intFromFloat(weighted * 100.0 + 0.5);
}
