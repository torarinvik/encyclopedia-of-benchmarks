package graph_c_undirected_simple

import "core:c"

MAX_VERTICES :: 32
MAX_EDGES :: 2047

put_i64 :: proc "contextless" (output: [^]u8, slot: c.size_t, value: i64) {
    bits := u64(value)
    for byte: c.size_t = 0; byte < 8; byte += 1 {
        output[slot * 8 + byte] = u8(bits >> (8 * byte))
    }
}

@(export)
graph_c_undirected_simple :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 do return -1
    if input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES do return -1
    vertices := c.size_t(input[0])
    edge_count := c.size_t(input[1])
    if length != 2 + 2 * edge_count do return -1

    adjacency: [MAX_VERTICES * MAX_VERTICES]i64
    for edge: c.size_t = 0; edge < edge_count; edge += 1 {
        left_value := input[2 + 2 * edge]
        right_value := input[3 + 2 * edge]
        if left_value < 0 || right_value < 0 || u64(left_value) >= u64(vertices) || u64(right_value) >= u64(vertices) do return -1
        left := c.size_t(left_value)
        right := c.size_t(right_value)
        adjacency[left * vertices + right] = 1
        adjacency[right * vertices + left] = 1
    }
    count := vertices * vertices
    if output == nil || capacity < count * 8 do return -2
    for row: c.size_t = 0; row < vertices; row += 1 {
        for column: c.size_t = 0; column < vertices; column += 1 {
            put_i64(output, row * vertices + column, adjacency[row * vertices + column])
        }
    }
    return i64(count * 8)
}
