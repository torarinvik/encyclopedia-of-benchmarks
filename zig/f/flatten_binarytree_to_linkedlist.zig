const MAX_NODE_COUNT: usize = 1023;
const MAX_TREE_HEIGHT: usize = 512;

fn validate(nodes: [*]const i64, count: usize, index: i64, depth: usize,
    visited: *[MAX_NODE_COUNT]bool, seen: *usize) bool {
    if (index == -1) return true;
    if (index < 0 or @as(u64, @intCast(index)) >= count or depth > MAX_TREE_HEIGHT) return false;
    const node: usize = @intCast(index);
    if (visited[node]) return false;
    visited[node] = true; seen.* += 1;
    const off = 3 * node;
    const value = nodes[off]; const left = nodes[off + 1]; const right = nodes[off + 2];
    if (value < -2147483648 or value > 2147483647 or left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= count) or
        (right >= 0 and @as(u64, @intCast(right)) >= count)) return false;
    return validate(nodes, count, left, depth + 1, visited, seen) and
        validate(nodes, count, right, depth + 1, visited, seen);
}

fn flatten(nodes: [*]i64, index: i64) void {
    if (index == -1) return;
    const off = 3 * @as(usize, @intCast(index));
    const left = nodes[off + 1];
    flatten(nodes, left);
    const original_right = nodes[off + 2];
    nodes[off + 2] = left; nodes[off + 1] = -1;
    var tail = index;
    while (nodes[3 * @as(usize, @intCast(tail)) + 2] != -1)
        tail = nodes[3 * @as(usize, @intCast(tail)) + 2];
    nodes[3 * @as(usize, @intCast(tail)) + 2] = original_right;
    flatten(nodes, original_right);
}

fn store(output: [*]u8, off: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[off + b] = @truncate(bits >> @as(u6, @intCast(8 * b)));
}

export fn flatten_binarytree_to_linkedlist(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or (length - 1) % 3 != 0 or
        length > 1 + 3 * MAX_NODE_COUNT) return -1;
    const count = (length - 1) / 3;
    const root = values[0];
    if (count == 0) return if (root == -1) 0 else -1;
    if (root < 0 or @as(u64, @intCast(root)) >= count) return -1;
    var nodes: [3 * MAX_NODE_COUNT]i64 = undefined;
    for (0..3 * count) |i| nodes[i] = values[i + 1];
    var visited: [MAX_NODE_COUNT]bool = undefined;
    for (0..count) |i| visited[i] = false;
    var seen: usize = 0;
    if (!validate(&nodes, count, root, 1, &visited, &seen) or seen != count) return -1;
    if (output == null or capacity < 24 * count) return -2;
    flatten(&nodes, root);
    for (0..count) |i| {
        store(output, 24 * i, nodes[3 * i]);
        store(output, 24 * i + 8, nodes[3 * i + 1]);
        store(output, 24 * i + 16, nodes[3 * i + 2]);
    }
    return @intCast(count);
}
