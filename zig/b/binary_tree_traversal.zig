const MAX_NODES: usize = 64;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_NODES;

fn walk(order: i64, values: *const [MAX_NODES]i64, left: *const [MAX_NODES]i64, right: *const [MAX_NODES]i64, node: usize, output: *[MAX_NODES]i64, used: *usize) void {
    if (order == 0) { output[used.*] = values[node]; used.* += 1; }
    if (left[node] >= 0) walk(order, values, left, right, @intCast(left[node]), output, used);
    if (order == 1) { output[used.*] = values[node]; used.* += 1; }
    if (right[node] >= 0) walk(order, values, left, right, @intCast(right[node]), output, used);
    if (order == 2) { output[used.*] = values[node]; used.* += 1; }
}

fn breadthFirst(order: i64, values: *const [MAX_NODES]i64, left: *const [MAX_NODES]i64, right: *const [MAX_NODES]i64, root: usize, output: *[MAX_NODES]i64, used: *usize) void {
    var queue: [MAX_NODES]usize = undefined;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = root;
    while (head < tail) {
        const node = queue[head];
        head += 1;
        output[used.*] = values[node];
        used.* += 1;
        const first = if (order == 3) left[node] else right[node];
        const second = if (order == 3) right[node] else left[node];
        if (first >= 0) { queue[tail] = @intCast(first); tail += 1; }
        if (second >= 0) { queue[tail] = @intCast(second); tail += 1; }
    }
}

fn breadthFirstZigzag(values: *const [MAX_NODES]i64, left: *const [MAX_NODES]i64, right: *const [MAX_NODES]i64, root: usize, output: *[MAX_NODES]i64, used: *usize) void {
    var queue: [MAX_NODES]usize = undefined;
    var head: usize = 0;
    var tail: usize = 1;
    var level: usize = 0;
    queue[0] = root;
    while (head < tail) {
        const level_end = tail;
        const start = used.*;
        while (head < level_end) {
            const node = queue[head]; head += 1;
            output[used.*] = values[node]; used.* += 1;
            if (left[node] >= 0) { queue[tail] = @intCast(left[node]); tail += 1; }
            if (right[node] >= 0) { queue[tail] = @intCast(right[node]); tail += 1; }
        }
        if (level % 2 == 1) {
            var lo = start;
            var hi = used.*;
            while (lo < hi) {
                hi -= 1;
                if (lo >= hi) break;
                const value = output[lo]; output[lo] = output[hi]; output[hi] = value;
                lo += 1;
            }
        }
        level += 1;
    }
}

fn markReachable(left: *const [MAX_NODES]i64, right: *const [MAX_NODES]i64, root: usize, seen: *[MAX_NODES]bool) usize {
    var stack: [MAX_NODES]usize = undefined;
    var top: usize = 1;
    var count: usize = 0;
    stack[0] = root;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (seen[node]) continue;
        seen[node] = true;
        count += 1;
        if (right[node] >= 0) { stack[top] = @intCast(right[node]); top += 1; }
        if (left[node] >= 0) { stack[top] = @intCast(left[node]); top += 1; }
    }
    return count;
}

fn putI64(output: [*c]u8, index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn binary_tree_traversal(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const order = input[0];
    const count_value = input[1];
    const root_value = input[2];
    if (order < 0 or order > 6 or count_value < 0 or count_value > @as(i64, @intCast(MAX_NODES))) return -1;
    const n: usize = @intCast(count_value);
    if (length != 3 + 3 * n or (n == 0 and root_value != -1) or (n > 0 and (root_value < 0 or root_value >= count_value))) return -1;
    var values: [MAX_NODES]i64 = undefined;
    var left: [MAX_NODES]i64 = undefined;
    var right: [MAX_NODES]i64 = undefined;
    var parents: [MAX_NODES]u8 = undefined;
    @memset(&parents, 0);
    for (0..n) |i| {
        values[i] = input[3 + 3 * i];
        left[i] = input[4 + 3 * i];
        right[i] = input[5 + 3 * i];
        if (left[i] < -1 or left[i] >= count_value or right[i] < -1 or right[i] >= count_value or left[i] == @as(i64, @intCast(i)) or right[i] == @as(i64, @intCast(i))) return -1;
        if (left[i] >= 0) { parents[@intCast(left[i])] += 1; if (parents[@intCast(left[i])] > 1) return -1; }
        if (right[i] >= 0) { parents[@intCast(right[i])] += 1; if (parents[@intCast(right[i])] > 1) return -1; }
    }
    var result: [MAX_NODES]i64 = undefined;
    var used: usize = 0;
    if (n > 0) {
        const root: usize = @intCast(root_value);
        for (0..n) |i| {
            if (parents[i] != (if (i == root) @as(u8, 0) else @as(u8, 1))) return -1;
        }
        var seen: [MAX_NODES]bool = undefined;
        @memset(&seen, false);
        if (markReachable(&left, &right, root, &seen) != n) return -1;
        if (order <= 2) walk(order, &values, &left, &right, root, &result, &used)
        else if (order == 5) walk(1, &values, &right, &left, root, &result, &used)
        else if (order == 6) breadthFirstZigzag(&values, &left, &right, root, &result, &used)
        else breadthFirst(order, &values, &left, &right, root, &result, &used);
    }
    if (output == null or capacity < used * 8) return -2;
    for (0..used) |i| putI64(output, i, result[i]);
    return @intCast(used * 8);
}
