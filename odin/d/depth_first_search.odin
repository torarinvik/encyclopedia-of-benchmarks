package depth_first_search

import "core:c"

// Traverse a directed graph from start with fixed-size adjacency bitsets.
@(export)
depth_first_search :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 66 || (length - 2) % 2 != 0 do return -2
    if values[0] < 0 || values[0] > 64 do return -2
    vertices := c.size_t(values[0])
    start_value := values[1]
    if vertices == 0 {
        if start_value == -1 && length == 2 do return 0
        return -2
    }
    if start_value < 0 || u64(start_value) >= u64(vertices) do return -2
    adjacency: [64]u64
    visited: [64]bool
    order: [64]c.size_t
    for vertex: c.size_t = 0; vertex < 64; vertex += 1 {
        adjacency[vertex] = 0
        visited[vertex] = false
    }
    edge_count := (length - 2) / 2
    for edge: c.size_t = 0; edge < edge_count; edge += 1 {
        origin_value := values[2 + 2 * edge]
        destination_value := values[3 + 2 * edge]
        if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
            return -2
        }
        origin := c.size_t(origin_value)
        destination := c.size_t(destination_value)
        adjacency[origin] |= u64(1) << destination
    }
    start := c.size_t(start_value)
    count := c.size_t(0)
    visited[start] = true
    stack_vertex: [64]c.size_t
    stack_next: [64]c.size_t
    depth := c.size_t(1)
    stack_vertex[0] = start
    order[count] = start
    count += 1
    for depth != 0 {
        frame := depth - 1
        origin := stack_vertex[frame]
        if stack_next[frame] == vertices {
            depth -= 1
        } else {
            destination := stack_next[frame]
            stack_next[frame] += 1
            if (adjacency[origin] & (u64(1) << destination)) != 0 && !visited[destination] {
                visited[destination] = true
                order[count] = destination
                count += 1
                stack_vertex[depth] = destination
                stack_next[depth] = 0
                depth += 1
            }
        }
    }
    if output_capacity < count || (count != 0 && output == nil) do return -2
    for index: c.size_t = 0; index < count; index += 1 {
        output[index] = u8(order[index])
    }
    return i64(count)
}
