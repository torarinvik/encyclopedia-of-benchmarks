/// Trim a strict BST and serialize the retained tree in preorder node-table order.
const MAX_NODE_COUNT: usize = 100;
const MAX_VALUE: i64 = 10000;

fn validBst(nodes: []const i64, node_count: usize, root_index: usize) bool {
    var parents: [MAX_NODE_COUNT]usize = @splat(0);
    for (0..node_count) |index| {
        const value = nodes[3 * index];
        const left = nodes[3 * index + 1];
        const right = nodes[3 * index + 2];
        if (value < 1 or value > MAX_VALUE or left < -1 or right < -1 or
            (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
            (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return false;
        if (left >= 0) {
            const child: usize = @intCast(left);
            parents[child] += 1;
            if (parents[child] > 1) return false;
        }
        if (right >= 0) {
            const child: usize = @intCast(right);
            parents[child] += 1;
            if (parents[child] > 1) return false;
        }
    }
    if (parents[root_index] != 0) return false;
    for (0..node_count) |index| if (index != root_index and parents[index] != 1) return false;

    var stack_node: [MAX_NODE_COUNT]usize = @splat(0);
    var stack_low: [MAX_NODE_COUNT]i64 = @splat(0);
    var stack_high: [MAX_NODE_COUNT]i64 = @splat(0);
    var seen: [MAX_NODE_COUNT]bool = @splat(false);
    var top: usize = 1;
    var visited: usize = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    while (top > 0) {
        top -= 1;
        const index = stack_node[top];
        const lower = stack_low[top];
        const upper = stack_high[top];
        if (seen[index]) return false;
        seen[index] = true;
        visited += 1;
        const value = nodes[3 * index];
        if (value <= lower or value >= upper) return false;
        const left = nodes[3 * index + 1];
        const right = nodes[3 * index + 2];
        if (right >= 0) {
            stack_node[top] = @intCast(right);
            stack_low[top] = value;
            stack_high[top] = upper;
            top += 1;
        }
        if (left >= 0) {
            stack_node[top] = @intCast(left);
            stack_low[top] = lower;
            stack_high[top] = value;
            top += 1;
        }
    }
    return visited == node_count;
}

fn trimNode(nodes: []const i64, node: i64, low: i64, high: i64,
            output: []i64, output_count: *usize) i64 {
    if (node == -1) return -1;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (value < low) return trimNode(nodes, right, low, high, output, output_count);
    if (value > high) return trimNode(nodes, left, low, high, output, output_count);
    const trimmed_index = output_count.*;
    output_count.* += 1;
    const offset = 1 + 3 * trimmed_index;
    output[offset] = value;
    output[offset + 1] = -1;
    output[offset + 2] = -1;
    output[offset + 1] = trimNode(nodes, left, low, high, output, output_count);
    output[offset + 2] = trimNode(nodes, right, low, high, output, output_count);
    return @intCast(trimmed_index);
}

export fn trim_bst(nodes: [*c]const i64, node_count: usize, root_index: i64,
                   low: i64, high: i64, output: [*c]i64, output_capacity: usize) i64 {
    if (node_count > MAX_NODE_COUNT or low < 1 or high > MAX_VALUE or low > high) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (output == null or output_capacity < 1) return -2;
        output[0] = -1;
        return 1;
    }
    if (nodes == null or root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    const node_values = nodes[0 .. 3 * node_count];
    if (!validBst(node_values, node_count, @intCast(root_index))) return -1;
    const required = 1 + 3 * node_count;
    if (output == null or output_capacity < required) return -2;
    const output_values = output[0..output_capacity];
    var output_count: usize = 0;
    output_values[0] = trimNode(node_values, root_index, low, high, output_values, &output_count);
    return @intCast(1 + 3 * output_count);
}
