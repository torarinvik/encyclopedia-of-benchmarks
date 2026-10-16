/// Detect cycles in a bounded simple undirected graph with iterative DFS.
export fn undirected_cycle_check(input: [*]const i64, length: usize) i64 {
    const max_vertices: usize = 32;
    const max_edges: usize = 256;
    const max_matrix: usize = max_vertices * max_vertices;
    if (length < 2 or input[0] < 0 or input[0] > 32 or input[1] < 0 or input[1] > 256) return -1;
    const vertices: usize = @intCast(input[0]);
    const edges: usize = @intCast(input[1]);
    if (length != 2 + 2 * edges) return -1;

    var adjacency: [max_matrix]bool = @splat(false);
    for (0..edges) |edge| {
        const left = input[2 + 2 * edge];
        const right = input[3 + 2 * edge];
        if (left < 0 or left >= @as(i64, @intCast(vertices)) or
            right < 0 or right >= @as(i64, @intCast(vertices))) return -1;
        const forward = @as(usize, @intCast(left)) * max_vertices + @as(usize, @intCast(right));
        const reverse = @as(usize, @intCast(right)) * max_vertices + @as(usize, @intCast(left));
        if (adjacency[forward]) return -1;
        adjacency[forward] = true;
        adjacency[reverse] = true;
    }

    var visited: [max_vertices]bool = @splat(false);
    var stack_vertex: [max_vertices]usize = undefined;
    var stack_parent: [max_vertices]usize = undefined;
    for (0..vertices) |start| {
        if (visited[start]) continue;
        var top: usize = 1;
        stack_vertex[0] = start;
        stack_parent[0] = max_vertices;
        visited[start] = true;
        while (top > 0) {
            top -= 1;
            const current = stack_vertex[top];
            const parent = stack_parent[top];
            for (0..vertices) |neighbor| {
                if (!adjacency[current * max_vertices + neighbor] or neighbor == parent) continue;
                if (visited[neighbor]) return 1;
                visited[neighbor] = true;
                stack_vertex[top] = neighbor;
                stack_parent[top] = current;
                top += 1;
            }
        }
    }
    return 0;
}
