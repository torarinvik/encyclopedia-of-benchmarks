const MAX_VERTICES: usize = 8;
const MAX_INPUT_LENGTH: usize = 58;

fn hasCycle(n: usize, graph: *const [MAX_VERTICES * MAX_VERTICES]u8, visited: *[MAX_VERTICES]bool, current: usize, position: usize) bool {
    if (position == n) return graph[current * MAX_VERTICES] != 0;
    for (0..n) |next| {
        if (graph[current * MAX_VERTICES + next] != 0 and !visited[next]) {
            visited[next] = true;
            if (hasCycle(n, graph, visited, next, position + 1)) return true;
            visited[next] = false;
        }
    }
    return false;
}

export fn hamiltonian_cycle_exists(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 3 or n_value > @as(i64, @intCast(MAX_VERTICES)) or m_value < 0) return -1;
    const n: usize = @intCast(n_value);
    if (m_value > @as(i64, @intCast(n * (n - 1) / 2))) return -1;
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * m) return -1;
    var graph = [_]u8{0} ** (MAX_VERTICES * MAX_VERTICES);
    for (0..m) |edge| {
        const u_value = input[2 + 2 * edge];
        const v_value = input[3 + 2 * edge];
        if (u_value < 0 or v_value < 0 or u_value >= n_value or v_value >= n_value or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (graph[u * MAX_VERTICES + v] != 0) return -1;
        graph[u * MAX_VERTICES + v] = 1;
        graph[v * MAX_VERTICES + u] = 1;
    }
    var visited = [_]bool{false} ** MAX_VERTICES;
    visited[0] = true;
    return if (hasCycle(n, &graph, &visited, 0, 1)) 1 else 0;
}
