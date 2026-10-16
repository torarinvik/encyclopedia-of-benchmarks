package breadth_first_search_shortest_path

import "core:c"

Max_Vertices :: 32
Max_Edges :: 256
Max_Input_Length :: 4 + 2 * Max_Edges
Max_Output_Values :: 1 + Max_Vertices

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
breadth_first_search_shortest_path :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > Max_Input_Length do return -1
    vertex_value, edge_value, start_value, goal_value := input[0], input[1], input[2], input[3]
    if vertex_value < 1 || vertex_value > Max_Vertices || edge_value < 0 || edge_value > Max_Edges do return -1
    vertices, edges := int(vertex_value), int(edge_value)
    if length != c.size_t(4 + 2 * edges) || start_value < 0 || start_value >= i64(vertices) || goal_value < 0 || goal_value >= i64(vertices) do return -1
    adjacency: [Max_Vertices * Max_Edges]int
    degree: [Max_Vertices]int
    for edge := 0; edge < edges; edge += 1 {
        from_value, to_value := input[4 + 2 * edge], input[5 + 2 * edge]
        if from_value < 0 || from_value >= i64(vertices) || to_value < 0 || to_value >= i64(vertices) do return -1
        source := int(from_value)
        adjacency[source * Max_Edges + degree[source]] = int(to_value)
        degree[source] += 1
    }
    start, goal := int(start_value), int(goal_value)
    parent: [Max_Vertices]i64
    visited: [Max_Vertices]bool
    queue: [Max_Vertices]int
    for vertex := 0; vertex < vertices; vertex += 1 { parent[vertex] = -1 }
    head, tail := 0, 0
    visited[start] = true
    queue[tail] = start
    tail += 1
    for head < tail && !visited[goal] {
        node := queue[head]
        head += 1
        for index := 0; index < degree[node]; index += 1 {
            neighbor := adjacency[node * Max_Edges + index]
            if visited[neighbor] do continue
            visited[neighbor] = true
            parent[neighbor] = i64(node)
            queue[tail] = neighbor
            tail += 1
            if neighbor == goal do break
        }
    }
    encoded: [Max_Output_Values]i64
    path_count := 0
    if visited[goal] {
        reverse_path: [Max_Vertices]int
        current := goal
        for current >= 0 {
            reverse_path[path_count] = current
            path_count += 1
            if current == start do break
            current = int(parent[current])
        }
        for index := 0; index < path_count; index += 1 { encoded[1 + index] = i64(reverse_path[path_count - 1 - index]) }
    }
    encoded[0] = i64(path_count)
    required := (path_count + 1) * 8
    if output == nil || capacity < c.size_t(required) do return -2
    for index := 0; index <= path_count; index += 1 { put_i64(output, index * 8, encoded[index]) }
    return i64(required)
}
