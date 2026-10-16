package depth_first_search_recursive

import "core:c"

MAX_VERTICES :: 64
MAX_EDGES :: 256
MAX_INPUT_LENGTH :: 518

reachable :: proc "contextless" (adjacency: [^]int, degree: [^]int, current: int,
    target: i64, visited: [^]bool) -> bool {
    if i64(current) == target do return true
    visited[current] = true
    for position := 0; position < degree[current]; position += 1 {
        neighbor := adjacency[current * MAX_VERTICES + position]
        if !visited[neighbor] && reachable(adjacency, degree, neighbor, target, visited) { return true }
    }
    return false
}

@(export)
depth_first_search_recursive :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    vertex_count, edge_count_value, source, target := input[0], input[1], input[2], input[3]
    if vertex_count < 1 || vertex_count > MAX_VERTICES || edge_count_value < 0
        || edge_count_value > MAX_EDGES || source < 0 || source >= vertex_count do return -1
    edge_count := int(edge_count_value)
    if int(length) != 4 + 2 * edge_count do return -1
    for edge := 0; edge < edge_count; edge += 1 {
        left, right := input[4 + 2 * edge], input[5 + 2 * edge]
        if left < 0 || left >= vertex_count || right < 0 || right >= vertex_count do return -1
    }

    adjacency: [MAX_VERTICES * MAX_VERTICES]int
    degree: [MAX_VERTICES]int = {}
    seen: [MAX_VERTICES]u64 = {}
    for edge := 0; edge < edge_count; edge += 1 {
        left, right := int(input[4 + 2 * edge]), int(input[5 + 2 * edge])
        right_bit := u64(1) << u64(right)
        if seen[left]&right_bit == 0 {
            seen[left] |= right_bit
            adjacency[left*MAX_VERTICES+degree[left]] = right
            degree[left] += 1
        }
        left_bit := u64(1) << u64(left)
        if seen[right]&left_bit == 0 {
            seen[right] |= left_bit
            adjacency[right*MAX_VERTICES+degree[right]] = left
            degree[right] += 1
        }
    }
    visited: [MAX_VERTICES]bool = {}
    if reachable(&adjacency[0], &degree[0], int(source), target, &visited[0]) do return 1
    return 0
}
