const std = @import("std");

const max_n: usize = 8;
const max_m: usize = 56;
const max_length: usize = 114;
const max_states: usize = 256;
const inf: i64 = std.math.maxInt(i64) / 4;

export fn minimum_directed_feedback_arc_set(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > max_length + 1) return -1;
    const words = input.?;
    if (words[0] < 1 or words[0] > @as(i64, @intCast(max_n)) or
        words[1] < 0 or words[1] > @as(i64, @intCast(max_m))) return -1;
    const n: usize = @intCast(words[0]);
    const m: usize = @intCast(words[1]);
    if (length != 2 + 2 * m) return -1;

    var outgoing = [_]usize{0} ** max_n;
    for (0..m) |edge| {
        const tail_value = words[2 + 2 * edge];
        const head_value = words[3 + 2 * edge];
        if (tail_value < 0 or head_value < 0 or
            @as(u64, @intCast(tail_value)) >= n or
            @as(u64, @intCast(head_value)) >= n or tail_value == head_value) return -1;
        const tail: usize = @intCast(tail_value);
        const head: usize = @intCast(head_value);
        const bit = @as(usize, 1) << @intCast(head);
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] |= bit;
    }

    const full = (@as(usize, 1) << @intCast(n)) - 1;
    var dp = [_]i64{inf} ** max_states;
    dp[0] = 0;
    for (0..full + 1) |prefix| {
        if (dp[prefix] == inf) continue;
        for (0..n) |vertex| {
            const bit = @as(usize, 1) << @intCast(vertex);
            if ((prefix & bit) != 0) continue;
            const backward: i64 = @intCast(@popCount(outgoing[vertex] & prefix));
            const target = prefix | bit;
            const candidate = dp[prefix] + backward;
            if (candidate < dp[target]) dp[target] = candidate;
        }
    }
    return dp[full];
}
