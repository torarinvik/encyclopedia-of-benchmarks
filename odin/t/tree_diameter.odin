package tree_diameter

import "core:c"

MAX_N :: 64
MAX_INPUT_VALUES :: 1 + 3 * (MAX_N - 1)
MAX_OUTPUT_VALUES :: 2 + MAX_N
MAX_EDGE_WEIGHT :: i64(1_000_000_000)

find_root :: proc "contextless" (parent: [^]int, item: int) -> int {
    current := item
    for parent[current] != current {
        parent[current] = parent[parent[current]]
        current = parent[current]
    }
    return current
}

traverse :: proc(n, start: int, adjacent: [^]bool, weight: [^]i64,
    distance, path_parent: [^]i64) {
    stack: [MAX_N]int
    for vertex := 0; vertex < n; vertex += 1 {
        distance[vertex] = -1
        path_parent[vertex] = -1
    }
    top := 1
    stack[0] = start
    distance[start] = 0
    for top > 0 {
        top -= 1
        vertex := stack[top]
        for neighbor := 0; neighbor < n; neighbor += 1 {
            matrix_index := vertex * MAX_N + neighbor
            if !adjacent[matrix_index] || distance[neighbor] >= 0 do continue
            distance[neighbor] = distance[vertex] + weight[matrix_index]
            path_parent[neighbor] = i64(vertex)
            stack[top] = neighbor
            top += 1
        }
    }
}

farthest :: proc(n: int, distance: [^]i64) -> int {
    best := 0
    for vertex := 1; vertex < n; vertex += 1 {
        if distance[vertex] > distance[best] ||
           (distance[vertex] == distance[best] && vertex < best) do best = vertex
    }
    return best
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
tree_diameter :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
    n_value := input[0]
    if n_value < 1 || n_value > MAX_N do return -1
    n := int(n_value)
    if length != c.size_t(1 + 3 * (n - 1)) do return -1

    adjacent: [MAX_N * MAX_N]bool
    weight: [MAX_N * MAX_N]i64
    for index := 0; index < MAX_N * MAX_N; index += 1 {
        adjacent[index] = false
        weight[index] = 0
    }
    dsu_parent: [MAX_N]int
    dsu_size: [MAX_N]int
    for vertex := 0; vertex < n; vertex += 1 {
        dsu_parent[vertex] = vertex
        dsu_size[vertex] = 1
    }
    for edge := 0; edge < n - 1; edge += 1 {
        offset := 1 + 3 * edge
        left_value := input[offset]
        right_value := input[offset + 1]
        edge_weight := input[offset + 2]
        if left_value < 0 || left_value >= n_value || right_value < 0 ||
           right_value >= n_value || left_value == right_value ||
           edge_weight < 1 || edge_weight > MAX_EDGE_WEIGHT do return -1
        left := int(left_value)
        right := int(right_value)
        root_left := find_root(&dsu_parent[0], left)
        root_right := find_root(&dsu_parent[0], right)
        if root_left == root_right do return -1
        if dsu_size[root_left] < dsu_size[root_right] {
            temporary := root_left
            root_left = root_right
            root_right = temporary
        }
        dsu_parent[root_right] = root_left
        dsu_size[root_left] += dsu_size[root_right]
        adjacent[left * MAX_N + right] = true
        adjacent[right * MAX_N + left] = true
        weight[left * MAX_N + right] = edge_weight
        weight[right * MAX_N + left] = edge_weight
    }

    distance: [MAX_N]i64
    path_parent: [MAX_N]i64
    traverse(n, 0, &adjacent[0], &weight[0], &distance[0], &path_parent[0])
    first_endpoint := farthest(n, &distance[0])
    traverse(n, first_endpoint, &adjacent[0], &weight[0], &distance[0], &path_parent[0])
    second_endpoint := farthest(n, &distance[0])
    reverse_path: [MAX_N]int
    path_length := 0
    current := i64(second_endpoint)
    for current >= 0 {
        reverse_path[path_length] = int(current)
        path_length += 1
        if int(current) == first_endpoint do break
        current = path_parent[int(current)]
    }
    staged: [MAX_OUTPUT_VALUES]i64
    used := 0
    staged[used] = distance[second_endpoint]
    used += 1
    staged[used] = i64(path_length)
    used += 1
    for position := 0; position < path_length; position += 1 {
        staged[used] = i64(reverse_path[path_length - 1 - position])
        used += 1
    }
    required := 8 * used
    if output == nil || capacity < c.size_t(required) do return -2
    for index := 0; index < used; index += 1 do store_i64_le(output, 8 * index, staged[index])
    return i64(required)
}
