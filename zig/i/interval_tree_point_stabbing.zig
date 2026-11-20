const std = @import("std");

const MAX_N: usize = 16;
const MAX_Q: usize = 8;
const TREE_CAP: usize = 32;
const MAX_OUTPUT: usize = 72;

const Interval = struct { low: i64 = 0, high: i64 = 0, id: usize = 0 };

fn writeI64Le(output: *[MAX_OUTPUT]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn interval_tree_point_stabbing(input: [*c]const i64, length: usize,
        output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 43) return -1;
    const n64 = input[0];
    const q64 = input[1];
    if (n64 < 0 or n64 > MAX_N or q64 < 0 or q64 > MAX_Q) return -1;
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    if (length != 2 + 2 * n + q) return -1;
    var sorted: [MAX_N]Interval = .{};
    var cursor: usize = 2;
    for (0..n) |id| {
        const low = input[cursor];
        const high = input[cursor + 1];
        cursor += 2;
        if (low < -32 or low > 32 or high < -32 or high > 32 or low > high) return -1;
        sorted[id] = .{ .low = low, .high = high, .id = id };
    }
    var points: [MAX_Q]i64 = .{};
    for (0..q) |index| {
        points[index] = input[cursor];
        cursor += 1;
        if (points[index] < -32 or points[index] > 32) return -1;
    }
    var index: usize = 1;
    while (index < n) : (index += 1) {
        const value = sorted[index];
        var position = index;
        while (position > 0) {
            const previous = sorted[position - 1];
            const greater = previous.low > value.low or
                (previous.low == value.low and previous.high > value.high) or
                (previous.low == value.low and previous.high == value.high and previous.id > value.id);
            if (!greater) break;
            sorted[position] = previous;
            position -= 1;
        }
        sorted[position] = value;
    }
    var tree: [TREE_CAP]Interval = .{};
    var used: [TREE_CAP]bool = .{};
    var maximum: [TREE_CAP]i64 = .{};
    @memset(&maximum, std.math.minInt(i64));
    var firsts: [MAX_N]usize = .{};
    var lasts: [MAX_N]usize = .{};
    var nodes: [MAX_N]usize = .{};
    if (n > 0) {
        var top: usize = 1;
        firsts[0] = 0; lasts[0] = n - 1; nodes[0] = 0;
        while (top > 0) {
            top -= 1;
            const first = firsts[top];
            const last = lasts[top];
            const node = nodes[top];
            if (first > last or node >= TREE_CAP) continue;
            const middle = first + (last - first) / 2;
            tree[node] = sorted[middle];
            used[node] = true;
            if (middle + 1 <= last) {
                firsts[top] = middle + 1; lasts[top] = last; nodes[top] = 2 * node + 2; top += 1;
            }
            if (first <= middle - 1) {
                firsts[top] = first; lasts[top] = middle - 1; nodes[top] = 2 * node + 1; top += 1;
            }
        }
    }
    var node: usize = TREE_CAP;
    while (node > 0) {
        node -= 1;
        if (!used[node]) continue;
        maximum[node] = tree[node].high;
        const left = 2 * node + 1;
        const right = left + 1;
        if (left < TREE_CAP and used[left] and maximum[left] > maximum[node]) maximum[node] = maximum[left];
        if (right < TREE_CAP and used[right] and maximum[right] > maximum[node]) maximum[node] = maximum[right];
    }
    var masks: [MAX_Q]i64 = .{};
    for (0..q) |qi| {
        var stack: [TREE_CAP]usize = .{};
        var top: usize = 0;
        if (n > 0) { stack[top] = 0; top += 1; }
        while (top > 0) {
            top -= 1;
            const current = stack[top];
            if (!used[current] or maximum[current] < points[qi]) continue;
            const left = 2 * current + 1;
            const right = left + 1;
            if (left < TREE_CAP and used[left] and maximum[left] >= points[qi]) { stack[top] = left; top += 1; }
            if (tree[current].low <= points[qi] and points[qi] <= tree[current].high)
                masks[qi] |= @as(i64, 1) << @intCast(tree[current].id);
            if (tree[current].low <= points[qi] and right < TREE_CAP and used[right] and maximum[right] >= points[qi]) {
                stack[top] = right; top += 1;
            }
        }
    }
    const bytes = (q + 1) * 8;
    if (output == null or capacity < bytes) return -2;
    var staged: [MAX_OUTPUT]u8 = .{};
    writeI64Le(&staged, 0, @intCast(q));
    for (0..q) |qi| writeI64Le(&staged, (qi + 1) * 8, masks[qi]);
    for (0..bytes) |index| output[index] = staged[index];
    return @intCast(bytes);
}

