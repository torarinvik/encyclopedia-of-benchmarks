/// Count nodes reachable from the root of a bounded indexed binary tree.
const MAX_NODE_COUNT: usize = 900;
const INVALID_RESULT: i64 = -9_000_000_000_000_000_000;

fn countVisit(nodes: [*]const i64, node_count: usize, node: i64, depth: usize) i64 {
    if (node < 0 or @as(u64, @intCast(node)) >= node_count or depth >= node_count) return INVALID_RESULT;
    const index: usize = @intCast(node);
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return INVALID_RESULT;
    const left_count = if (left == -1) 0 else countVisit(nodes, node_count, left, depth + 1);
    if (left_count == INVALID_RESULT) return INVALID_RESULT;
    const right_count = if (right == -1) 0 else countVisit(nodes, node_count, right, depth + 1);
    if (right_count == INVALID_RESULT) return INVALID_RESULT;
    return 1 + left_count + right_count;
}

export fn binary_tree_node_count(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count == 0 or node_count > MAX_NODE_COUNT or root_index < 0 or
        @as(u64, @intCast(root_index)) >= node_count) return INVALID_RESULT;
    return countVisit(nodes, node_count, root_index, 0);
}
