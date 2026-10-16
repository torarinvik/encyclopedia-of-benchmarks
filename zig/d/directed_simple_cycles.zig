/// Enumerate directed simple cycles in source DFS order.
const MAX_VERTICES = 6;
const MAX_EDGES = MAX_VERTICES * MAX_VERTICES;
const MAX_OUTPUT_BYTES = 2786;

export fn directed_simple_cycles(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const input_values = input.?;
    const vertex_value = input_values[0];
    const edge_value = input_values[1];
    if (vertex_value < 0 or vertex_value > MAX_VERTICES or edge_value < 0 or edge_value > MAX_EDGES) return -1;
    const vertices: usize = @intCast(vertex_value);
    const edges: usize = @intCast(edge_value);
    if (length != 2 + 2 * edges) return -1;

    var adjacency: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    for (0..edges) |edge| {
        const source = input_values[2 + 2 * edge];
        const destination = input_values[3 + 2 * edge];
        if (source < 0 or source >= vertex_value or destination < 0 or destination >= vertex_value) return -1;
        adjacency[@as(usize, @intCast(source)) * MAX_VERTICES + @as(usize, @intCast(destination))] = true;
    }

    var scratch: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var output_length: usize = 0;
    for (0..vertices) |start| {
        var path: [MAX_VERTICES]usize = @splat(0);
        var next_neighbor: [MAX_VERTICES]usize = @splat(0);
        var visited: [MAX_VERTICES]bool = @splat(false);
        var depth: usize = 0;
        path[0] = start;
        visited[start] = true;
        while (true) {
            const current = path[depth];
            if (next_neighbor[depth] == vertices) {
                visited[current] = false;
                if (depth == 0) break;
                depth -= 1;
                continue;
            }
            const neighbor = next_neighbor[depth];
            next_neighbor[depth] += 1;
            if (!adjacency[current * MAX_VERTICES + neighbor]) continue;
            if (neighbor == start) {
                for (0..depth + 1) |index| { scratch[output_length] = @intCast(path[index]); output_length += 1; }
                scratch[output_length] = @intCast(start); output_length += 1;
                scratch[output_length] = 255; output_length += 1;
            } else if (!visited[neighbor]) {
                depth += 1;
                path[depth] = neighbor;
                next_neighbor[depth] = 0;
                visited[neighbor] = true;
            }
        }
        for (0..vertices) |vertex| {
            adjacency[start * MAX_VERTICES + vertex] = false;
            adjacency[vertex * MAX_VERTICES + start] = false;
        }
    }
    if (output_length == 0) return 0;
    if (capacity < output_length) return -2;
    const output_bytes = output orelse return -2;
    @memcpy(output_bytes[0..output_length], scratch[0..output_length]);
    return @intCast(output_length);
}
