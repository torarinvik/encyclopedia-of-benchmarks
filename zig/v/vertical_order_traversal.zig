const MAX_NODES: usize = 1023;
const COLUMN_COUNT: usize = 2 * MAX_NODES + 1;

export fn vertical_order_traversal(nodes: [*]const i64, node_count: usize,
    root_index: i64, output_values: [*]i64, output_capacity: usize,
    column_offsets: [*]usize, offsets_capacity: usize,
    queue: [*]usize, queue_capacity: usize) i64 {
    if (node_count > MAX_NODES) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (offsets_capacity < 1) return -2;
        column_offsets[0] = 0;
        return 0;
    }
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;
    if (output_capacity < node_count or offsets_capacity < node_count + 1 or queue_capacity < node_count) return -2;
    const root: usize = @intCast(root_index);
    var parents = [_]usize{0} ** MAX_NODES;
    for (0..node_count) |node| {
        const value = nodes[3 * node];
        const left = nodes[3 * node + 1];
        const right = nodes[3 * node + 2];
        if (value < -2147483648 or value > 2147483647 or left < -1 or right < -1 or
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
    if (parents[root] != 0) return -1;
    for (0..node_count) |node| if (node != root and parents[node] != 1) return -1;
    var column = [_]i64{0} ** MAX_NODES;
    var next_column = [_]i64{0} ** MAX_NODES;
    var bucket_head = [_]i64{-1} ** COLUMN_COUNT;
    var bucket_tail = [_]i64{-1} ** COLUMN_COUNT;
    var visited = [_]bool{false} ** MAX_NODES;
    var head: usize = 0;
    var tail: usize = 1;
    var reached: usize = 0;
    var minimum: i64 = 0;
    var maximum: i64 = 0;
    queue[0] = root;
    column[root] = 0;
    visited[root] = true;
    while (head < tail) {
        const node = queue[head]; head += 1;
        const coordinate = column[node];
        const slot: usize = @intCast(coordinate + MAX_NODES);
        next_column[node] = -1;
        if (bucket_head[slot] < 0) {
            bucket_head[slot] = @intCast(node);
        } else {
            next_column[@intCast(bucket_tail[slot])] = @intCast(node);
        }
        bucket_tail[slot] = @intCast(node);
        reached += 1;
        const left = nodes[3 * node + 1];
        const right = nodes[3 * node + 2];
        if (left >= 0) {
            const child: usize = @intCast(left);
            if (visited[child] or tail >= queue_capacity) return -1;
            visited[child] = true;
            column[child] = coordinate - 1;
            queue[tail] = child; tail += 1;
            minimum = @min(minimum, column[child]);
        }
        if (right >= 0) {
            const child: usize = @intCast(right);
            if (visited[child] or tail >= queue_capacity) return -1;
            visited[child] = true;
            column[child] = coordinate + 1;
            queue[tail] = child; tail += 1;
            maximum = @max(maximum, column[child]);
        }
    }
    if (reached != node_count) return -1;
    var written: usize = 0;
    var column_count: usize = 0;
    column_offsets[0] = 0;
    var coordinate = minimum;
    while (coordinate <= maximum) : (coordinate += 1) {
        const slot: usize = @intCast(coordinate + MAX_NODES);
        var node = bucket_head[slot];
        while (node >= 0) {
            output_values[written] = nodes[3 * @as(usize, @intCast(node))];
            written += 1;
            node = next_column[@intCast(node)];
        }
        column_count += 1;
        column_offsets[column_count] = written;
    }
    return @intCast(column_count);
}
