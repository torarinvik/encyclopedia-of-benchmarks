/// Count the path through the selected node, matching Node.diameter().
const MAX_NODE_COUNT: usize = 1023;
const ERROR_SENTINEL: i64 = -2_000_000_000;

fn heightAndCheck(nodes: [*]const i64, count: usize, node: i64,
    seen: *[MAX_NODE_COUNT]bool, visited: *usize) i64 {
    if (node == -1) return 0;
    if (node < 0 or @as(u64, @intCast(node)) >= count) return ERROR_SENTINEL;
    const index: usize = @intCast(node);
    if (seen[index]) return ERROR_SENTINEL;
    seen[index] = true;
    visited.* += 1;
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= count) or
        (right >= 0 and @as(u64, @intCast(right)) >= count)) return ERROR_SENTINEL;
    const left_height = heightAndCheck(nodes, count, left, seen, visited);
    if (left_height == ERROR_SENTINEL) return ERROR_SENTINEL;
    const right_height = heightAndCheck(nodes, count, right, seen, visited);
    if (right_height == ERROR_SENTINEL) return ERROR_SENTINEL;
    return 1 + @max(left_height, right_height);
}

export fn diameter_of_binary_tree(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count == 0 or node_count > MAX_NODE_COUNT or root_index < 0 or
        @as(u64, @intCast(root_index)) >= node_count) return -1;
    const root: usize = @intCast(root_index);
    const left = nodes[3 * root + 1];
    const right = nodes[3 * root + 2];
    if (left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
    var seen: [MAX_NODE_COUNT]bool = @splat(false);
    seen[root] = true;
    var visited: usize = 1;
    const left_height = heightAndCheck(nodes, node_count, left, &seen, &visited);
    if (left_height == ERROR_SENTINEL) return -1;
    const right_height = heightAndCheck(nodes, node_count, right, &seen, &visited);
    if (right_height == ERROR_SENTINEL or visited != node_count) return -1;
    return left_height + right_height + 1;
}
