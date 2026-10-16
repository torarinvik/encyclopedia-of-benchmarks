/// Detect directed cycles with iterative three-color depth-first search.
export fn check_cycle(input: [*]const i64, length: usize) i64 {
    const max_vertices: usize = 32;
    const max_edges: usize = 256;
    const max_matrix: usize = max_vertices * max_vertices;
    if (length < 2 or input[0] < 0 or input[0] > 32 or input[1] < 0 or input[1] > 256) return -1;
    const vertices: usize = @intCast(input[0]);
    const edges: usize = @intCast(input[1]);
    if (length != 2 + 2 * edges) return -1;

    var adjacency: [max_matrix]bool = @splat(false);
    for (0..edges) |edge| {
        const origin = input[2 + 2 * edge];
        const destination = input[3 + 2 * edge];
        if (origin < 0 or origin >= @as(i64, @intCast(vertices)) or
            destination < 0 or destination >= @as(i64, @intCast(vertices))) return -1;
        adjacency[@as(usize, @intCast(origin)) * max_vertices + @as(usize, @intCast(destination))] = true;
    }

    var color: [max_vertices]u8 = @splat(0);
    var stack: [max_vertices]usize = undefined;
    var next_neighbor: [max_vertices]usize = @splat(0);
    for (0..vertices) |start| {
        if (color[start] != 0) continue;
        var top: usize = 1;
        stack[0] = start;
        next_neighbor[0] = 0;
        color[start] = 1;
        while (top > 0) {
            const frame = top - 1;
            const current = stack[frame];
            while (next_neighbor[frame] < vertices and
                !adjacency[current * max_vertices + next_neighbor[frame]]) next_neighbor[frame] += 1;
            if (next_neighbor[frame] == vertices) {
                color[current] = 2;
                top -= 1;
                continue;
            }
            const neighbor = next_neighbor[frame];
            next_neighbor[frame] += 1;
            if (color[neighbor] == 1) return 1;
            if (color[neighbor] == 0) {
                color[neighbor] = 1;
                stack[top] = neighbor;
                next_neighbor[top] = 0;
                top += 1;
            }
        }
    }
    return 0;
}
