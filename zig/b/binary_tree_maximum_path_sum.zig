/// Carry the largest downward gain upward and update the best path at each node.
const MAX_NODE_COUNT: usize = 1023;
const ERROR_SENTINEL: i64 = -2_000_000_000;

fn maximumGain(nodes: [*]const i64, node_count: usize, node: i64, best_path: *i64) i64 {
    if (node == -1) return 0;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return ERROR_SENTINEL;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (value < -1000 or value > 1000 or left < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or right < -1 or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return ERROR_SENTINEL;
    const left_gain = maximumGain(nodes, node_count, left, best_path);
    if (left_gain == ERROR_SENTINEL) return ERROR_SENTINEL;
    const right_gain = maximumGain(nodes, node_count, right, best_path);
    if (right_gain == ERROR_SENTINEL) return ERROR_SENTINEL;
    const positive_left = @max(left_gain, 0);
    const positive_right = @max(right_gain, 0);
    const through_node = value + positive_left + positive_right;
    best_path.* = @max(best_path.*, through_node);
    return value + @max(positive_left, positive_right);
}

export fn binary_tree_maximum_path_sum(nodes: [*]const i64, node_count: usize,
                                       root_index: i64) i64 {
    if (node_count == 0 or node_count > MAX_NODE_COUNT or root_index < 0 or
        @as(u64, @intCast(root_index)) >= node_count) return -1;
    var best_path: i64 = -2_147_483_648;
    const gain = maximumGain(nodes, node_count, root_index, &best_path);
    if (gain == ERROR_SENTINEL) return -1;
    return best_path;
}
