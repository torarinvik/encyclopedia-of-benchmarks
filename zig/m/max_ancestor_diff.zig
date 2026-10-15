/// Recursively carry the minimum and maximum ancestor values down each path.
const MAX_NODE_COUNT: usize = 1023;

fn visit(nodes: [*]const i64, node_count: usize, node: i64, path_min: i64, path_max: i64) i64 {
    if (node == -1) return 0;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return -1;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    if (value < -100_000 or value > 100_000) return -1;
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
    const low_difference = if (path_min >= value) path_min - value else value - path_min;
    const high_difference = if (path_max >= value) path_max - value else value - path_max;
    const best = @max(low_difference, high_difference);
    const low = @min(path_min, value);
    const high = @max(path_max, value);
    const left_best = visit(nodes, node_count, left, low, high);
    if (left_best < 0) return -1;
    const right_best = visit(nodes, node_count, right, low, high);
    if (right_best < 0) return -1;
    return @max(best, @max(left_best, right_best));
}

/// Return the maximum absolute difference between a node and any ancestor.
export fn max_ancestor_diff(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count == 0 or node_count > MAX_NODE_COUNT or root_index < 0 or
        @as(u64, @intCast(root_index)) >= node_count) return -1;
    const root: usize = @intCast(root_index);
    const root_value = nodes[3 * root];
    if (root_value < -100_000 or root_value > 100_000) return -1;
    return visit(nodes, node_count, root_index, root_value, root_value);
}
