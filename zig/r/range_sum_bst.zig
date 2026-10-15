/// Preserve the source's full tree traversal while validating the BST input.
const MAX_NODE_COUNT: usize = 1023;
const MAX_VALUE: i64 = 100_000;

export fn range_sum_bst(nodes: [*]const i64, node_count: usize,
    root_index: i64, low: i64, high: i64) i64 {
    if (node_count > MAX_NODE_COUNT or low < 1 or high > MAX_VALUE or low > high) return -1;
    if (node_count == 0) return if (root_index == -1) 0 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;

    var parents: [MAX_NODE_COUNT]i64 = @splat(0);
    var seen: [MAX_NODE_COUNT]bool = @splat(false);
    var stack_node: [MAX_NODE_COUNT]i64 = undefined;
    var stack_low: [MAX_NODE_COUNT]i64 = undefined;
    var stack_high: [MAX_NODE_COUNT]i64 = undefined;
    for (0..node_count) |index| {
        const value = nodes[3 * index];
        const left = nodes[3 * index + 1];
        const right = nodes[3 * index + 2];
        if (value < 1 or value > MAX_VALUE or left < -1 or right < -1 or
            (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
            (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
        if (left >= 0) {
            const child: usize = @intCast(left);
            parents[child] += 1;
            if (parents[child] > 1) return -1;
        }
        if (right >= 0) {
            const child: usize = @intCast(right);
            parents[child] += 1;
            if (parents[child] > 1) return -1;
        }
    }
    const root: usize = @intCast(root_index);
    if (parents[root] != 0) return -1;
    for (0..node_count) |index| {
        if (index != root and parents[index] != 1) return -1;
    }

    var top: usize = 1;
    var visited: usize = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    var total: i64 = 0;
    while (top > 0) {
        top -= 1;
        const index: usize = @intCast(stack_node[top]);
        const lower = stack_low[top];
        const upper = stack_high[top];
        if (seen[index]) return -1;
        seen[index] = true;
        visited += 1;
        const value = nodes[3 * index];
        const left = nodes[3 * index + 1];
        const right = nodes[3 * index + 2];
        if (value <= lower or value >= upper) return -1;
        if (low <= value and value <= high) total += value;
        if (right >= 0) {
            stack_node[top] = right;
            stack_low[top] = value;
            stack_high[top] = upper;
            top += 1;
        }
        if (left >= 0) {
            stack_node[top] = left;
            stack_low[top] = lower;
            stack_high[top] = value;
            top += 1;
        }
    }
    if (visited != node_count) return -1;
    return total;
}
