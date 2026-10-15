/// Sum leaf values reached through left-child links.
const MAX_NODE_COUNT: usize = 1023;
const ERROR_SENTINEL: i64 = -2_000_000_000;

fn visit(nodes: [*]const i64, node_count: usize, node: i64, is_left: bool) i64 {
    if (node == -1) return 0;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return ERROR_SENTINEL;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (value < -1000 or value > 1000 or left < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or right < -1 or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return ERROR_SENTINEL;
    if (left == -1 and right == -1) return if (is_left) value else 0;
    const left_sum = visit(nodes, node_count, left, true);
    if (left_sum == ERROR_SENTINEL) return ERROR_SENTINEL;
    const right_sum = visit(nodes, node_count, right, false);
    if (right_sum == ERROR_SENTINEL) return ERROR_SENTINEL;
    return left_sum + right_sum;
}

export fn sum_of_left_leaves(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 0 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    const result = visit(nodes, node_count, root_index, false);
    return if (result == ERROR_SENTINEL) -1 else result;
}
