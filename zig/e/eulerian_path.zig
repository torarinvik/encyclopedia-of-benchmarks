/// Construct a directed Eulerian path with iterative Hierholzer traversal.
const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 256;

fn put_i64(output: [*]u8, byte_offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte_offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn eulerian_path(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length < 2 or input[0] < 0 or input[0] > 32 or input[1] < 0 or input[1] > 256) return -1;
    const vertices: usize = @intCast(input[0]);
    const edges: usize = @intCast(input[1]);
    if (length != 2 + 2 * edges) return -1;

    var adjacency: [MAX_VERTICES][MAX_EDGES]u8 = undefined;
    var in_degree: [MAX_VERTICES]usize = @splat(0);
    var out_degree: [MAX_VERTICES]usize = @splat(0);
    for (0..edges) |edge| {
        const source = input[2 + 2 * edge];
        const destination = input[3 + 2 * edge];
        if (source < 0 or source >= @as(i64, @intCast(vertices)) or
            destination < 0 or destination >= @as(i64, @intCast(vertices))) return -1;
        const source_index: usize = @intCast(source);
        const destination_index: usize = @intCast(destination);
        adjacency[source_index][out_degree[source_index]] = @intCast(destination_index);
        out_degree[source_index] += 1;
        in_degree[destination_index] += 1;
    }
    if (edges == 0) return 0;

    var start: usize = 0;
    var start_count: usize = 0;
    var end_count: usize = 0;
    for (0..vertices) |vertex| {
        const difference = @as(i64, @intCast(out_degree[vertex])) - @as(i64, @intCast(in_degree[vertex]));
        if (difference == 1) {
            start = vertex;
            start_count += 1;
        } else if (difference == -1) {
            end_count += 1;
        } else if (difference != 0) return 0;
    }
    if (!((start_count == 0 and end_count == 0) or (start_count == 1 and end_count == 1))) return 0;
    if (start_count == 0) {
        while (start < vertices and out_degree[start] == 0) start += 1;
        if (start == vertices) return 0;
    }

    var remaining = out_degree;
    var stack: [MAX_EDGES + 1]usize = undefined;
    var reverse_path: [MAX_EDGES + 1]usize = undefined;
    var top: usize = 1;
    var path_count: usize = 0;
    stack[0] = start;
    while (top > 0) {
        const current = stack[top - 1];
        if (remaining[current] > 0) {
            remaining[current] -= 1;
            stack[top] = adjacency[current][remaining[current]];
            top += 1;
        } else {
            top -= 1;
            reverse_path[path_count] = stack[top];
            path_count += 1;
        }
    }
    if (path_count != edges + 1) return 0;
    const bytes = path_count * 8;
    if (capacity < bytes) return -2;
    for (0..path_count) |index| put_i64(output, index * 8, @intCast(reverse_path[path_count - index - 1]));
    return @intCast(bytes);
}
