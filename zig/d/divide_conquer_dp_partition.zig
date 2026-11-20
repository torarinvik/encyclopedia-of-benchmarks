const std = @import("std");
const MaxN: usize = 64;
const MaxGroups: usize = 8;
const MaxInput: usize = 66;
const StackCapacity: usize = 136;
const Inf: i64 = std.math.maxInt(i64) / 4;

const Task = struct { left: usize, right: usize, low: usize, high: usize };

fn computeRow(previous: []const i64, current: []i64, prefix: []const i64,
               n: usize, group: usize) void {
    var stack: [StackCapacity]Task = undefined;
    var top: usize = 1;
    stack[0] = .{ .left = group, .right = n, .low = group - 1, .high = n - 1 };
    while (top != 0) {
        top -= 1;
        const task = stack[top];
        if (task.left > task.right) continue;
        const middle = task.left + (task.right - task.left) / 2;
        const upper = @min(task.high, middle - 1);
        var best = Inf;
        var best_split = task.low;
        for (task.low..upper + 1) |split| {
            if (previous[split] == Inf) continue;
            const segment = prefix[middle] - prefix[split];
            const candidate = previous[split] + segment * segment;
            if (candidate < best) { best = candidate; best_split = split; }
        }
        current[middle] = best;
        if (middle < task.right) {
            stack[top] = .{ .left = middle + 1, .right = task.right, .low = best_split, .high = task.high };
            top += 1;
        }
        if (task.left < middle) {
            stack[top] = .{ .left = task.left, .right = middle - 1, .low = task.low, .high = best_split };
            top += 1;
        }
    }
}

export fn divide_conquer_dp_partition(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 3 or length > MaxInput) return -1;
    const values = values_opt.?;
    const n_value = values[0];
    const groups_value = values[1];
    if (n_value < 1 or n_value > MaxN or groups_value < 1 or groups_value > MaxGroups or
        groups_value > n_value or length != @as(usize, @intCast(n_value)) + 2) return -1;
    const n: usize = @intCast(n_value);
    const groups: usize = @intCast(groups_value);
    var prefix: [MaxN + 1]i64 = @splat(0);
    var previous: [MaxN + 1]i64 = @splat(Inf);
    var current: [MaxN + 1]i64 = @splat(Inf);
    for (0..n) |i| {
        const value = values[i + 2];
        if (value < 0 or value > 1000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    previous[0] = 0;
    for (1..groups + 1) |group| {
        @memset(current[0 .. n + 1], Inf);
        computeRow(previous[0 .. n + 1], current[0 .. n + 1], prefix[0 .. n + 1], n, group);
        std.mem.swap([MaxN + 1]i64, &previous, &current);
    }
    return previous[n];
}
