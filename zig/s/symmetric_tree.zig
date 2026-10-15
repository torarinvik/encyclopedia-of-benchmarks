/// Recursively compare opposite child pairs in an indexed binary tree.
const MAX_NODE_COUNT: usize = 1023;

fn mirror(nodes: [*]const i64, node_count: usize, left: i64, right: i64) i64 {
    if (left == -1 or right == -1) return if (left == right) 1 else 0;
    if (left < 0 or right < 0 or @as(u64, @intCast(left)) >= node_count or
        @as(u64, @intCast(right)) >= node_count) return -1;
    const left_node: usize = @intCast(left);
    const right_node: usize = @intCast(right);
    if (nodes[3 * left_node] != nodes[3 * right_node]) return 0;
    const left_left = nodes[3 * left_node + 1];
    const left_right = nodes[3 * left_node + 2];
    const right_left = nodes[3 * right_node + 1];
    const right_right = nodes[3 * right_node + 2];
    if (left_left < -1 or (left_left >= 0 and @as(u64, @intCast(left_left)) >= node_count) or
        left_right < -1 or (left_right >= 0 and @as(u64, @intCast(left_right)) >= node_count) or
        right_left < -1 or (right_left >= 0 and @as(u64, @intCast(right_left)) >= node_count) or
        right_right < -1 or (right_right >= 0 and @as(u64, @intCast(right_right)) >= node_count)) return -1;
    const outer = mirror(nodes, node_count, left_left, right_right);
    if (outer != 1) return outer;
    return mirror(nodes, node_count, left_right, right_left);
}

/// Return 1 when the indexed tree mirrors itself, 0 when it does not, or -1 for an invalid root.
export fn symmetric_tree(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 1 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    const root: usize = @intCast(root_index);
    const left = nodes[3 * root + 1];
    const right = nodes[3 * root + 2];
    if (left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
    return mirror(nodes, node_count, left, right);
}
