package topological_sort_dfs

import "core:c"

// Deterministic depth-first topological sort with three-color cycle detection.
@(export)
topological_sort_dfs :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > 66 || (length - 1) % 2 != 0 do return -2
    if values[0] < 0 || values[0] > 40 do return -2
    vertices := c.size_t(values[0])
    edge_count := (length - 1) / 2
    adjacency: [40]u64
    state: [40]u8
    stack: [40]c.size_t
    next_neighbor: [40]c.size_t
    order: [40]c.size_t
    for vertex: c.size_t = 0; vertex < 40; vertex += 1 {
        adjacency[vertex] = 0
        state[vertex] = 0
    }
    for edge: c.size_t = 0; edge < edge_count; edge += 1 {
        origin_value := values[1 + 2 * edge]
        destination_value := values[2 + 2 * edge]
        if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
            return -2
        }
        origin := c.size_t(origin_value)
        destination := c.size_t(destination_value)
        adjacency[origin] |= u64(1) << destination
    }

    count := c.size_t(0)
    for root: c.size_t = 0; root < vertices; root += 1 {
        if state[root] != 0 do continue
        top := c.size_t(0)
        stack[top] = root
        next_neighbor[top] = 0
        state[root] = 1
        for {
            origin := stack[top]
            destination := next_neighbor[top]
            for destination < vertices && (adjacency[origin] & (u64(1) << destination)) == 0 {
                destination += 1
            }
            if destination == vertices {
                state[origin] = 2
                order[count] = origin
                count += 1
                if top == 0 do break
                top -= 1
                continue
            }
            next_neighbor[top] = destination + 1
            if state[destination] == 1 do return -1
            if state[destination] == 0 {
                top += 1
                stack[top] = destination
                next_neighbor[top] = 0
                state[destination] = 1
            }
        }
    }

    if output_capacity < vertices || (vertices != 0 && output == nil) do return -2
    for index: c.size_t = 0; index < count; index += 1 {
        output[index] = u8(order[count - 1 - index])
    }
    return i64(count)
}
