const MAX_VERTICES: usize = 14;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 17;

fn findRoot(parent: *[MAX_VERTICES]usize, vertex_input: usize) usize {
    var vertex = vertex_input;
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

export fn mcoloring(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const colors_value = input[1];
    if (n_value < 0 or n_value > MAX_VERTICES or colors_value < 1 or colors_value > MAX_VERTICES) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 2) return -1;

    var masks = [_]u32{0} ** MAX_VERTICES;
    var parent = [_]usize{0} ** MAX_VERTICES;
    const valid_mask: u32 = if (n == 0) 0 else (@as(u32, 1) << @intCast(n)) - 1;
    for (0..n) |vertex| {
        const raw = input[vertex + 2];
        if (raw < 0 or @as(u64, @intCast(raw)) > valid_mask) return -1;
        masks[vertex] = @intCast(raw);
        if (masks[vertex] & (@as(u32, 1) << @intCast(vertex)) != 0) return -1;
        parent[vertex] = vertex;
    }
    for (0..n) |vertex| {
        for (vertex + 1..n) |neighbor| {
            const edge = masks[vertex] & (@as(u32, 1) << @intCast(neighbor)) != 0;
            if (edge != (masks[neighbor] & (@as(u32, 1) << @intCast(vertex)) != 0)) return -1;
            if (edge) {
                const root_a = findRoot(&parent, vertex);
                const root_b = findRoot(&parent, neighbor);
                if (root_a == root_b) return -1;
                parent[root_a] = root_b;
            }
        }
    }

    var colors = [_]i32{1} ** MAX_VERTICES;
    var visited = [_]bool{false} ** MAX_VERTICES;
    var queue = [_]usize{0} ** MAX_VERTICES;
    var maximum_color: i32 = 1;
    for (0..n) |start| {
        if (visited[start]) continue;
        var head: usize = 0;
        var tail: usize = 0;
        visited[start] = true;
        queue[tail] = start;
        tail += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            for (0..n) |neighbor| {
                if (masks[vertex] & (@as(u32, 1) << @intCast(neighbor)) == 0) continue;
                if (colors[vertex] == colors[neighbor]) colors[neighbor] += 1;
                maximum_color = @max(maximum_color, @max(colors[vertex], colors[neighbor]));
                if (maximum_color > @as(i32, @intCast(colors_value))) return 0;
                if (!visited[neighbor]) {
                    visited[neighbor] = true;
                    queue[tail] = neighbor;
                    tail += 1;
                }
            }
        }
    }
    return 1;
}
