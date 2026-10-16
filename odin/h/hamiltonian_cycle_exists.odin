package hamiltonian_cycle_exists

import "core:c"

MAX_VERTICES :: 8
MAX_INPUT_LENGTH :: 58

has_cycle :: proc "contextless" (n: int, graph: ^[MAX_VERTICES * MAX_VERTICES]u8, visited: ^[MAX_VERTICES]bool, current, position: int) -> bool {
    if position == n { return graph[current * MAX_VERTICES] != 0 }
    for next := 0; next < n; next += 1 {
        if graph[current * MAX_VERTICES + next] != 0 && !visited[next] {
            visited[next] = true
            if has_cycle(n, graph, visited, next, position + 1) { return true }
            visited[next] = false
        }
    }
    return false
}

@(export)
hamiltonian_cycle_exists :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 3 || input[0] > MAX_VERTICES || input[1] < 0 do return -1
    n := int(input[0])
    if input[1] > i64(n * (n - 1) / 2) do return -1
    m := int(input[1])
    if length != c.size_t(2 + 2 * m) do return -1
    var graph: [MAX_VERTICES * MAX_VERTICES]u8
    for edge := 0; edge < m; edge += 1 {
        u_value := input[2 + 2 * edge]; v_value := input[3 + 2 * edge]
        if u_value < 0 || v_value < 0 || u_value >= i64(n) || v_value >= i64(n) || u_value == v_value do return -1
        u := int(u_value); v := int(v_value)
        if graph[u * MAX_VERTICES + v] != 0 do return -1
        graph[u * MAX_VERTICES + v] = 1
        graph[v * MAX_VERTICES + u] = 1
    }
    var visited: [MAX_VERTICES]bool
    visited[0] = true
    if has_cycle(n, &graph, &visited, 0, 1) { return 1 }
    return 0
}
