/// Eagerly materialize a BST's in-order sequence, then consume it through an iterator.
const MAX_NODE_COUNT: usize = 1023;

export fn bst_iterator(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 0 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;

    var iterator_values: [MAX_NODE_COUNT]i64 = undefined;
    var stack: [MAX_NODE_COUNT]usize = undefined;
    var top: usize = 0;
    var value_count: usize = 0;
    var current = root_index;
    while (current != -1 or top != 0) {
        while (current != -1) {
            if (current < 0 or @as(u64, @intCast(current)) >= node_count or top >= node_count) return -1;
            const index: usize = @intCast(current);
            const left = nodes[3 * index + 1];
            const right = nodes[3 * index + 2];
            if (left < -1 or (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
                right < -1 or (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return -1;
            stack[top] = index;
            top += 1;
            current = left;
        }
        top -= 1;
        const index = stack[top];
        if (value_count >= node_count) return -1;
        const value = nodes[3 * index];
        if (value < -100_000 or value > 100_000 or
            (value_count != 0 and iterator_values[value_count - 1] >= value)) return -1;
        iterator_values[value_count] = value;
        value_count += 1;
        current = nodes[3 * index + 2];
    }
    if (value_count != node_count) return -1;

    var checksum: i64 = 0;
    var next_index: usize = 0;
    while (next_index < value_count) : (next_index += 1) {
        checksum += (@as(i64, @intCast(next_index)) + 1) * (iterator_values[next_index] + 100_001);
    }
    return checksum;
}
