const MAX_VERTEX_COUNT: usize = 64;
const MAX_EDGE_COUNT: usize = 2046;
const MAX_INPUT_LENGTH: usize = 4 + 2 * MAX_EDGE_COUNT;

export fn bfs_queue(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 4 or length > MAX_INPUT_LENGTH or input[0] < 1 or
        input[0] > @as(i64, @intCast(MAX_VERTEX_COUNT)) or input[3] < 0 or
        input[3] > @as(i64, @intCast(MAX_EDGE_COUNT))) return -1;
    const vertex_count: usize = @intCast(input[0]);
    const source_arg = input[1];
    const target_arg = input[2];
    const edge_count: usize = @intCast(input[3]);
    if (source_arg < 0 or source_arg >= @as(i64, @intCast(vertex_count)) or
        target_arg < 0 or target_arg >= @as(i64, @intCast(vertex_count)) or
        length != 4 + 2 * edge_count) return -1;

    var adjacency: [MAX_VERTEX_COUNT]u64 = @splat(0);
    for (0..edge_count) |edge| {
        const left_arg = input[4 + 2 * edge];
        const right_arg = input[5 + 2 * edge];
        if (left_arg < 0 or right_arg < 0 or left_arg >= @as(i64, @intCast(vertex_count)) or
            right_arg >= @as(i64, @intCast(vertex_count))) return -1;
        const left: usize = @intCast(left_arg);
        const right: usize = @intCast(right_arg);
        adjacency[left] |= @as(u64, 1) << @intCast(right);
        adjacency[right] |= @as(u64, 1) << @intCast(left);
    }

    const source: usize = @intCast(source_arg);
    const target: usize = @intCast(target_arg);
    var predecessor: [MAX_VERTEX_COUNT]i64 = @splat(-1);
    var visited: [MAX_VERTEX_COUNT]bool = @splat(false);
    var queue: [MAX_VERTEX_COUNT]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    predecessor[source] = @intCast(source);
    visited[source] = true;
    queue[0] = source;
    var found = source == target;
    while (head < tail and !found) {
        const current = queue[head];
        head += 1;
        for (0..vertex_count) |neighbor| {
            if (adjacency[current] & (@as(u64, 1) << @intCast(neighbor)) == 0 or visited[neighbor]) continue;
            visited[neighbor] = true;
            predecessor[neighbor] = @intCast(current);
            if (neighbor == target) { found = true; break; }
            queue[tail] = neighbor;
            tail += 1;
        }
    }
    if (!found) {
        if (output_capacity < 1) return -2;
        output[0] = 0;
        return 1;
    }

    var path: [MAX_VERTEX_COUNT]u8 = @splat(0);
    var path_length: usize = 0;
    var current = target;
    while (current != source) {
        path[path_length] = @intCast(current);
        path_length += 1;
        current = @intCast(predecessor[current]);
    }
    path[path_length] = @intCast(source);
    path_length += 1;
    if (path_length + 1 > output_capacity) return -2;
    output[0] = 1;
    for (0..path_length) |index| output[index + 1] = path[index];
    return @intCast(path_length + 1);
}
