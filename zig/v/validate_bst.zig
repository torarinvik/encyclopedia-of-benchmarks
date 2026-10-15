/// Check strict BST bounds over a valid indexed binary tree.
const MAX_NODE_COUNT: usize = 1023;

fn validateSubtree(nodes: [*]const i64, node_count: usize, node: i64,
                   has_lower: bool, lower: i64, has_upper: bool, upper: i64) i64 {
    if (node == -1) return 1;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return -1;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (value < -2147483648 or value > 2147483647 or
        left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
    if ((has_lower and value <= lower) or (has_upper and value >= upper)) return 0;
    const left_result = validateSubtree(nodes, node_count, left, has_lower, lower, true, value);
    if (left_result <= 0) return left_result;
    return validateSubtree(nodes, node_count, right, true, value, has_upper, upper);
}

export fn validate_bst(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 1 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    return validateSubtree(nodes, node_count, root_index, false, 0, false, 0);
}
