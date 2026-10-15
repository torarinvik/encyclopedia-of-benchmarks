/// One-pass postorder height computation, following the pinned Java method.
const MAX_NODE_COUNT: usize = 1023;

fn balancedHeight(nodes: [*]const i64, count: usize, node: i64, balanced: *bool) i64 {
    if (node == -1 or !balanced.*) return 0;
    if (node < 0 or @as(u64, @intCast(node)) >= count) return -1;
    const index: usize = @intCast(node);
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= count) or
        right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= count)) return -1;
    const left_height = balancedHeight(nodes, count, left, balanced);
    if (left_height < 0) return -1;
    const right_height = balancedHeight(nodes, count, right, balanced);
    if (right_height < 0) return -1;
    const difference = if (left_height >= right_height)
        left_height - right_height
    else
        right_height - left_height;
    if (difference > 1) balanced.* = false;
    return 1 + @max(left_height, right_height);
}

export fn check_if_binary_tree_balanced(nodes: [*]const i64, node_count: usize,
    root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 1 else -1;
    if (@as(u64, @intCast(root_index)) >= node_count or root_index < 0) return -1;
    var balanced = true;
    const height = balancedHeight(nodes, node_count, root_index, &balanced);
    if (height < 0) return -1;
    return if (balanced) 1 else 0;
}
