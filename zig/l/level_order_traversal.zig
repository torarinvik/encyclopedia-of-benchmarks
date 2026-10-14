/// Breadth-first indexed binary-tree traversal, recording each level boundary.
export fn level_order_traversal(
    nodes: [*]const i64,
    node_count: usize,
    root_index: i64,
    output_values: [*]i64,
    output_capacity: usize,
    level_offsets: [*]usize,
    level_offsets_capacity: usize,
    queue: [*]usize,
    queue_capacity: usize,
) i64 {
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (level_offsets_capacity < 1) return -2;
        level_offsets[0] = 0;
        return 0;
    }
    if (node_count > 4096 or root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    if (output_capacity < node_count or level_offsets_capacity < node_count + 1 or
        queue_capacity < node_count) return -2;

    var head: usize = 0;
    var tail: usize = 1;
    var visited: usize = 0;
    var levels: usize = 0;
    queue[0] = @intCast(root_index);
    level_offsets[0] = 0;
    while (head < tail) {
        const level_end = tail;
        while (head < level_end) {
            const node = queue[head];
            head += 1;
            output_values[visited] = nodes[3 * node];
            visited += 1;
            const left = nodes[3 * node + 1];
            const right = nodes[3 * node + 2];
            if (left < -1 or right < -1) return -1;
            if (left >= 0) {
                if (@as(u64, @intCast(left)) >= node_count or tail >= queue_capacity) return -1;
                queue[tail] = @intCast(left);
                tail += 1;
            }
            if (right >= 0) {
                if (@as(u64, @intCast(right)) >= node_count or tail >= queue_capacity) return -1;
                queue[tail] = @intCast(right);
                tail += 1;
            }
        }
        levels += 1;
        level_offsets[levels] = visited;
    }
    if (visited != node_count) return -1;
    return @intCast(levels);
}
