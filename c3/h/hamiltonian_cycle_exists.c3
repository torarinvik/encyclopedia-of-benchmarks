module hamiltonian_cycle_exists;

const usz MAX_VERTICES = 8;
const usz MAX_INPUT_LENGTH = 58;

fn bool has_cycle(usz n, char* graph, bool* visited, usz current, usz position) {
    if (position == n) return graph[current * MAX_VERTICES] != 0;
    for (usz next = 0; next < n; next++) {
        if (graph[current * MAX_VERTICES + next] != 0 && !visited[next]) {
            visited[next] = true;
            if (has_cycle(n, graph, visited, next, position + 1)) return true;
            visited[next] = false;
        }
    }
    return false;
}

fn long hamiltonian_cycle_exists(long* input, usz length) @export("hamiltonian_cycle_exists") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 3 || input[0] > (long)MAX_VERTICES || input[1] < 0) return -1;
    usz n = (usz)input[0];
    if (input[1] > (long)(n * (n - 1) / 2)) return -1;
    usz m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;
    char[MAX_VERTICES * MAX_VERTICES] graph;
    for (usz i = 0; i < MAX_VERTICES * MAX_VERTICES; i++) graph[i] = 0;
    for (usz edge = 0; edge < m; edge++) {
        long u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= (long)n || v_value >= (long)n || u_value == v_value) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        if (graph[u * MAX_VERTICES + v] != 0) return -1;
        graph[u * MAX_VERTICES + v] = 1;
        graph[v * MAX_VERTICES + u] = 1;
    }
    bool[MAX_VERTICES] visited;
    for (usz i = 0; i < MAX_VERTICES; i++) visited[i] = false;
    visited[0] = true;
    return has_cycle(n, &graph[0], &visited[0], 0, 1) ? 1 : 0;
}
