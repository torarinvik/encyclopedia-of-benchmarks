package topological

import "core:c"

// Source-faithful port of TheAlgorithms/Go graph.Topological.
@(export)
topological :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > 66 || (length - 1) % 2 != 0 do return -2
    if values[0] < 0 || values[0] > 64 do return -2
    vertices := c.size_t(values[0])
    edge_count := (length - 1) / 2
    dependencies: [64]u8
    adjacency: [64]u64
    answer: [96]u8
    for vertex: c.size_t = 0; vertex < 64; vertex += 1 {
        dependencies[vertex] = 0
        adjacency[vertex] = 0
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
        dependencies[destination] += 1
        adjacency[origin] |= u64(1) << u32(destination)
    }

    answer_count := c.size_t(0)
    for root: c.size_t = 0; root < vertices; root += 1 {
        if dependencies[root] != 0 do continue
        stack: [64]c.size_t
        top := c.size_t(0)
        stack[top] = root
        top += 1
        for top > 0 {
            top -= 1
            origin := stack[top]
            answer[answer_count] = u8(origin)
            answer_count += 1
            for destination: c.size_t = 0; destination < vertices; destination += 1 {
                edge_mask := u64(1) << u32(destination)
                if adjacency[origin] & edge_mask != 0 {
                    in_stack := false
                    for index: c.size_t = 0; index < top; index += 1 {
                        if stack[index] == destination {
                            in_stack = true
                            break
                        }
                    }
                    if !in_stack {
                        stack[top] = destination
                        top += 1
                    }
                }
                adjacency[origin] &= ~edge_mask
                adjacency[destination] &= ~(u64(1) << u32(origin))
            }
        }
    }

    if output_capacity < answer_count || (answer_count != 0 && output == nil) do return -2
    for index: c.size_t = 0; index < answer_count; index += 1 {
        output[index] = answer[index]
    }
    return i64(answer_count)
}
