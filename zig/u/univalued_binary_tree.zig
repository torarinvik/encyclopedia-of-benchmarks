/// Recursively check each node against its parent value.
const MAX_NODE_COUNT: usize = 1023;

fn isUnivalued(nodes: [*]const i64, node_count: usize, node: i64) i64 {
    if (node == -1) return 1;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return -1;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
    if ((left >= 0 and nodes[3 * @as(usize, @intCast(left))] != value) or
        (right >= 0 and nodes[3 * @as(usize, @intCast(right))] != value)) return 0;
    const left_result = isUnivalued(nodes, node_count, left);
    if (left_result <= 0) return left_result;
    return isUnivalued(nodes, node_count, right);
}

export fn univalued_binary_tree(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 1 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    return isUnivalued(nodes, node_count, root_index);
}
