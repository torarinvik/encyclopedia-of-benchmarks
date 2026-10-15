/// Recursive inorder traversal that writes into caller-owned storage.
const MAX_NODE_COUNT: usize = 100;

fn inorderVisit(nodes: [*]const i64, node_count: usize, node: i64,
    output: [*]i64, capacity: usize, used: *usize) bool {
    if (node == -1) return true;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return false;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (value < -100 or value > 100 or left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return false;
    if (!inorderVisit(nodes, node_count, left, output, capacity, used)) return false;
    if (used.* >= capacity) return false;
    output[used.*] = value;
    used.* += 1;
    return inorderVisit(nodes, node_count, right, output, capacity, used);
}

export fn binary_tree_inorder_traversal(nodes: [*]const i64, node_count: usize,
    root_index: i64, output: [*]i64, output_capacity: usize) i64 {
    if (node_count > MAX_NODE_COUNT or output_capacity < node_count) return -1;
    if (node_count == 0) return if (root_index == -1) 0 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    var used: usize = 0;
    if (!inorderVisit(nodes, node_count, root_index, output, output_capacity, &used) or
        used != node_count) return -1;
    return @intCast(used);
}
