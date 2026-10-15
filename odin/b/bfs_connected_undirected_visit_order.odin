package bfs_connected_undirected_visit_order

import "core:c"

MAX_VERTICES :: 40
MAX_EDGES :: 780

put_i64 :: proc "contextless" (output: [^]u8, slot: c.size_t, value: i64) {
    bits := u64(value)
    for byte: c.size_t = 0; byte < 8; byte += 1 {
        output[slot * 8 + byte] = u8(bits >> (8 * byte))
    }
}

@(export)
bfs_connected_undirected_visit_order :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 do return -1
    if input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES || input[2] != 0 do return -1
    vertices := c.size_t(input[0])
    edge_count := c.size_t(input[1])
    if length != 3 + 2 * edge_count do return -1

    adjacency: [MAX_VERTICES]u64
    for i: c.size_t = 0; i < MAX_VERTICES; i += 1 do adjacency[i] = 0
    for edge: c.size_t = 0; edge < edge_count; edge += 1 {
        left_value := input[3 + 2 * edge]
        right_value := input[4 + 2 * edge]
        if left_value < 0 || right_value < 0 || u64(left_value) >= u64(vertices) || u64(right_value) >= u64(vertices) do return -1
        left := c.size_t(left_value)
        right := c.size_t(right_value)
        adjacency[left] |= u64(1) << right
        adjacency[right] |= u64(1) << left
    }
    visited: [MAX_VERTICES]bool
    queue, order: [MAX_VERTICES]c.size_t
    for i: c.size_t = 0; i < MAX_VERTICES; i += 1 do visited[i] = false
    head, tail, count := c.size_t(0), c.size_t(0), c.size_t(0)
    visited[0] = true
    queue[tail] = 0
    tail += 1
    for head < tail {
        vertex := queue[head]
        head += 1
        order[count] = vertex
        count += 1
        for neighbor: c.size_t = 0; neighbor < vertices; neighbor += 1 {
            if (adjacency[vertex] & (u64(1) << neighbor)) != 0 && !visited[neighbor] {
                visited[neighbor] = true
                queue[tail] = neighbor
                tail += 1
            }
        }
    }
    if count != vertices do return -1
    if output == nil || capacity < vertices * 8 do return -2
    for i: c.size_t = 0; i < count; i += 1 do put_i64(output, i, i64(order[i]))
    return i64(count)
}
