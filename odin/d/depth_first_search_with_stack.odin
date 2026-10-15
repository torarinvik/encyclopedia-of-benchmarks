package depth_first_search_with_stack

import "core:c"

// Stack-based DFS that marks vertices when they are pushed, matching the source order.
@(export)
depth_first_search_with_stack :: proc "c" (values: [^]i64, length: c.size_t,
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

    adjacency: [2048]c.size_t
    degree: [64]c.size_t
    state: [64]u8
    for index: c.size_t = 0; index < 2048; index += 1 { adjacency[index] = 0 }
    for index: c.size_t = 0; index < 64; index += 1 {
        degree[index] = 0
        state[index] = 0
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
        adjacency[origin * 32 + degree[origin]] = c.size_t(destination_value)
        degree[origin] += 1
    }

    stack: [33]c.size_t
    order: [64]c.size_t
    stack_length := c.size_t(1)
    count := c.size_t(0)
    start := c.size_t(start_value)
    state[start] = 1
    stack[0] = start
    for stack_length != 0 {
        stack_length -= 1
        vertex := stack[stack_length]
        if state[vertex] != 1 do continue
        order[count] = vertex
        count += 1
        for edge: c.size_t = 0; edge < degree[vertex]; edge += 1 {
            neighbor := adjacency[vertex * 32 + edge]
            stack[stack_length] = neighbor
            stack_length += 1
            if state[neighbor] != 2 do state[neighbor] = 1
        }
        state[vertex] = 2
    }
    if output_capacity < count || output == nil do return -2
    for index: c.size_t = 0; index < count; index += 1 {
        output[index] = u8(order[index])
    }
    return i64(count)
}
