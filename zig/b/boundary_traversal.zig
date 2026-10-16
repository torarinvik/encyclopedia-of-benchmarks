const MAX_NODE_COUNT: usize = 100;

fn validateTree(nodes: [*c]const i64, node_count: usize, node: i64,
    seen: [*]bool, reached: *usize) bool {
    if (node == -1) return true;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return false;
    const index: usize = @intCast(node);
    if (seen[index]) return false;
    seen[index] = true;
    reached.* += 1;
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (value < -2147483648 or value > 2147483647 or left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return false;
    return validateTree(nodes, node_count, left, seen, reached) and
        validateTree(nodes, node_count, right, seen, reached);
}

fn isLeaf(nodes: [*c]const i64, index: usize) bool {
    return nodes[3 * index + 1] == -1 and nodes[3 * index + 2] == -1;
}

fn emitLeaves(nodes: [*c]const i64, node: i64, output: [*c]i64, used: *usize) void {
    if (node == -1) return;
    const index: usize = @intCast(node);
    if (isLeaf(nodes, index)) {
        output[used.*] = nodes[3 * index];
        used.* += 1;
        return;
    }
    emitLeaves(nodes, nodes[3 * index + 1], output, used);
    emitLeaves(nodes, nodes[3 * index + 2], output, used);
}

export fn boundary_traversal(nodes: [*c]const i64, node_count: usize, root_index: i64,
    output: [*c]i64, output_capacity: usize) i64 {
    if (node_count > MAX_NODE_COUNT or output_capacity < node_count) return -1;
    if (node_count == 0) return if (root_index == -1) 0 else -1;
    if (nodes == null or output == null or root_index < 0 or
        @as(u64, @intCast(root_index)) >= node_count) return -1;

    var seen: [MAX_NODE_COUNT]bool = @splat(false);
    var reached: usize = 0;
    if (!validateTree(nodes, node_count, root_index, &seen, &reached) or reached != node_count) return -1;

    const root: usize = @intCast(root_index);
    var used: usize = 0;
    if (!isLeaf(nodes, root)) {
        output[used] = nodes[3 * root];
        used += 1;
    }

    var current = nodes[3 * root + 1];
    if (current == -1 and nodes[3 * root + 2] != -1) current = nodes[3 * root + 2];
    while (current != -1) {
        const index: usize = @intCast(current);
        if (!isLeaf(nodes, index)) {
            output[used] = nodes[3 * index];
            used += 1;
        }
        current = if (nodes[3 * index + 1] != -1)
            nodes[3 * index + 1]
        else
            nodes[3 * index + 2];
    }

    emitLeaves(nodes, root_index, output, &used);
    if (nodes[3 * root + 2] != -1 and nodes[3 * root + 1] == -1) return @intCast(used);

    var right_boundary: [MAX_NODE_COUNT]i64 = undefined;
    var right_count: usize = 0;
    current = nodes[3 * root + 2];
    while (current != -1) {
        const index: usize = @intCast(current);
        if (!isLeaf(nodes, index)) {
            right_boundary[right_count] = nodes[3 * index];
            right_count += 1;
        }
        current = if (nodes[3 * index + 2] != -1)
            nodes[3 * index + 2]
        else
            nodes[3 * index + 1];
    }
    while (right_count > 0) {
        right_count -= 1;
        output[used] = right_boundary[right_count];
        used += 1;
    }
    return @intCast(used);
}
