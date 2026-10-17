const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 48;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;
const MAX_ROUTE: usize = MAX_EDGES + 1;

fn writeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn hierholzer_eulerian_path(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const vertex_count_value = input[0];
    const edge_count_value = input[1];
    if (vertex_count_value < 0 or vertex_count_value > @as(i64, MAX_VERTICES) or
        edge_count_value < 0 or edge_count_value > @as(i64, MAX_EDGES)) return -1;
    const vertex_count: usize = @intCast(vertex_count_value);
    const edge_count: usize = @intCast(edge_count_value);
    if (length != 2 + 2 * edge_count) return -1;

    var adjacency: [MAX_VERTICES][MAX_EDGES]i32 = undefined;
    var in_degree: [MAX_VERTICES]usize = @splat(0);
    var out_degree: [MAX_VERTICES]usize = @splat(0);
    for (0..edge_count) |edge| {
        const source_value = input[2 + 2 * edge];
        const destination_value = input[3 + 2 * edge];
        if (source_value < 0 or source_value >= vertex_count_value or
            destination_value < 0 or destination_value >= vertex_count_value) return -1;
        const source: usize = @intCast(source_value);
        const destination: usize = @intCast(destination_value);
        adjacency[source][out_degree[source]] = @intCast(destination);
        out_degree[source] += 1;
        in_degree[destination] += 1;
    }

    var path: [MAX_ROUTE]usize = undefined;
    var path_length: usize = 0;
    if (vertex_count == 0) {
        path_length = 0;
    } else if (edge_count == 0) {
        path[0] = 0;
        path_length = 1;
    } else {
        var start: ?usize = null;
        var start_count: usize = 0;
        var end_count: usize = 0;
        var degrees_valid = true;
        for (0..vertex_count) |vertex| {
            const difference = @as(i64, @intCast(out_degree[vertex])) - @as(i64, @intCast(in_degree[vertex]));
            if (difference == 1) {
                start = vertex;
                start_count += 1;
            } else if (difference == -1) {
                end_count += 1;
            } else if (difference < -1 or difference > 1) {
                degrees_valid = false;
            }
        }
        if (!((start_count == 1 and end_count == 1) or
            (start_count == 0 and end_count == 0))) degrees_valid = false;
        if (degrees_valid and start == null) {
            for (0..vertex_count) |vertex| {
                if (out_degree[vertex] > 0) { start = vertex; break; }
            }
        }

        var connected = degrees_valid;
        if (connected) {
            const start_vertex = start.?;
            var visited: [MAX_VERTICES]bool = @splat(false);
            var pending: [MAX_VERTICES]usize = undefined;
            var pending_head: usize = 0;
            var pending_tail: usize = 1;
            pending[0] = start_vertex;
            visited[start_vertex] = true;
            while (pending_head < pending_tail) {
                const current = pending[pending_head];
                pending_head += 1;
                for (0..out_degree[current]) |edge| {
                    const next: usize = @intCast(adjacency[current][edge]);
                    if (!visited[next]) {
                        visited[next] = true;
                        pending[pending_tail] = next;
                        pending_tail += 1;
                    }
                }
                for (0..vertex_count) |source| {
                    if (visited[source]) continue;
                    for (0..out_degree[source]) |edge| {
                        if (adjacency[source][edge] == @as(i32, @intCast(current))) {
                            visited[source] = true;
                            pending[pending_tail] = source;
                            pending_tail += 1;
                            break;
                        }
                    }
                }
            }
            for (0..vertex_count) |vertex| {
                if (in_degree[vertex] + out_degree[vertex] > 0 and !visited[vertex]) connected = false;
            }
        }

        if (connected) {
            const start_vertex = start.?;
            var next_position: [MAX_VERTICES]usize = @splat(0);
            var stack: [MAX_ROUTE]usize = undefined;
            var reverse_path: [MAX_ROUTE]usize = undefined;
            var stack_size: usize = 1;
            var reverse_length: usize = 0;
            stack[0] = start_vertex;
            while (stack_size > 0) {
                const current = stack[stack_size - 1];
                if (next_position[current] < out_degree[current]) {
                    const next: usize = @intCast(adjacency[current][next_position[current]]);
                    next_position[current] += 1;
                    stack[stack_size] = next;
                    stack_size += 1;
                } else {
                    stack_size -= 1;
                    reverse_path[reverse_length] = stack[stack_size];
                    reverse_length += 1;
                }
            }
            if (reverse_length == edge_count + 1) {
                path_length = reverse_length;
                for (0..path_length) |index| path[index] = reverse_path[path_length - 1 - index];
            }
        }
    }

    const output_bytes = 8 * (path_length + 1);
    if (output == null or capacity < output_bytes) return -2;
    writeI64Le(output, 0, @intCast(path_length));
    for (0..path_length) |index| writeI64Le(output, 8 * (index + 1), @intCast(path[index]));
    return @intCast(output_bytes);
}
