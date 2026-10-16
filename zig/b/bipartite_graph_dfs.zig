const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;
const MAX_CELLS: usize = MAX_VERTICES * MAX_VERTICES;

pub export fn bipartite_graph_dfs(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > MAX_VERTICES or m_value < 0 or m_value > MAX_EDGES) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;

    var adjacency: [MAX_CELLS]bool = @splat(false);
    for (0..m) |edge| {
        const from_value = input[2 + 2 * edge];
        const to_value = input[3 + 2 * edge];
        if (from_value < 0 or from_value >= @as(i64, @intCast(n)) or to_value < 0 or to_value >= @as(i64, @intCast(n))) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        adjacency[from * n + to] = true;
        adjacency[to * n + from] = true;
    }
    var color: [MAX_VERTICES]i8 = @splat(-1);
    var stack: [MAX_VERTICES]usize = @splat(0);
    for (0..n) |start| {
        if (color[start] != -1) continue;
        var top: usize = 1;
        stack[0] = start;
        color[start] = 0;
        while (top > 0) {
            top -= 1;
            const node = stack[top];
            for (0..n) |neighbor| {
                if (!adjacency[node * n + neighbor]) continue;
                if (color[neighbor] == -1) {
                    color[neighbor] = 1 - color[node];
                    stack[top] = neighbor;
                    top += 1;
                } else if (color[neighbor] == color[node]) return 0;
            }
        }
    }
    return 1;
}
