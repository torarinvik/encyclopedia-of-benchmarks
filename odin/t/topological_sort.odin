package topological_sort

import "core:c"

// Kahn topological sort over a bounded directed graph encoded as edge pairs.
@(export)
topological_sort :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > 66 || (length - 1) % 2 != 0 do return -2
    if values[0] < 0 || values[0] > 64 do return -2
    vertices := c.size_t(values[0])
    edge_count := (length - 1) / 2
    adjacency: [64]u64
    indegree: [64]c.size_t
    queue: [64]c.size_t
    order: [64]c.size_t

    for vertex: c.size_t = 0; vertex < 64; vertex += 1 {
        adjacency[vertex] = 0
        indegree[vertex] = 0
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
        mask := u64(1) << destination
        if (adjacency[origin] & mask) == 0 {
            adjacency[origin] |= mask
            indegree[destination] += 1
        }
    }
    head := c.size_t(0)
    tail := c.size_t(0)
    for vertex: c.size_t = 0; vertex < vertices; vertex += 1 {
        if indegree[vertex] == 0 {
            queue[tail] = vertex
            tail += 1
        }
    }
    count := c.size_t(0)
    for head < tail {
        origin := queue[head]
        head += 1
        order[count] = origin
        count += 1
        for destination: c.size_t = 0; destination < vertices; destination += 1 {
            if (adjacency[origin] & (u64(1) << destination)) != 0 {
                indegree[destination] -= 1
                if indegree[destination] == 0 {
                    queue[tail] = destination
                    tail += 1
                }
            }
        }
    }
    if count != vertices do return -1
    if output_capacity < vertices || (vertices != 0 && output == nil) do return -2
    for index: c.size_t = 0; index < count; index += 1 {
        output[index] = u8(order[index])
    }
    return i64(count)
}
