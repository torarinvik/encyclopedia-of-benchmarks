/// Preserve recursive height calculation followed by recursive balance checks.
const MAX_NODE_COUNT: usize = 1023;

fn treeHeight(nodes: [*]const i64, node_count: usize, node: i64) i64 {
    if (node == -1) return 0;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return -1;
    const index: usize = @intCast(node);
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
    const left_height = treeHeight(nodes, node_count, left);
    if (left_height < 0) return -1;
    const right_height = treeHeight(nodes, node_count, right);
    if (right_height < 0) return -1;
    return 1 + @max(left_height, right_height);
}

fn balancedVisit(nodes: [*]const i64, node_count: usize, node: i64) i64 {
    if (node == -1) return 1;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return -1;
    const index: usize = @intCast(node);
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
    const left_height = treeHeight(nodes, node_count, left);
    if (left_height < 0) return -1;
    const right_height = treeHeight(nodes, node_count, right);
    if (right_height < 0) return -1;
    const difference = if (left_height >= right_height)
        left_height - right_height
    else
        right_height - left_height;
    if (difference > 1) return 0;
    const left_balanced = balancedVisit(nodes, node_count, left);
    if (left_balanced <= 0) return left_balanced;
    return balancedVisit(nodes, node_count, right);
}

export fn balanced_binary_tree(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 1 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    return balancedVisit(nodes, node_count, root_index);
}
