package zero_one_bfs

import "core:c"

// 0-1 BFS over a bounded directed graph encoded as weighted edge triples.
@(export)
zero_one_bfs :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 3 || length > 3075 do return -1
    if values[0] < 1 || values[0] > 64 || values[2] < 0 || values[2] > 1024 do return -1
    vertices := c.size_t(values[0])
    source_value := values[1]
    edge_count := c.size_t(values[2])
    if source_value < 0 || u64(source_value) >= u64(vertices) || length != 3 + 3 * edge_count do return -1
    source := c.size_t(source_value)

    zero_edges: [64]u64
    one_edges: [64]u64
    distance: [64]u8
    deque: [4097]u8
    for vertex: c.size_t = 0; vertex < 64; vertex += 1 {
        zero_edges[vertex] = 0
        one_edges[vertex] = 0
        distance[vertex] = 255
    }
    for edge: c.size_t = 0; edge < edge_count; edge += 1 {
        origin_value := values[3 + 3 * edge]
        destination_value := values[4 + 3 * edge]
        weight := values[5 + 3 * edge]
        if origin_value < 0 || destination_value < 0 ||
                u64(origin_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) ||
                (weight != 0 && weight != 1) {
            return -1
        }
        origin := c.size_t(origin_value)
        destination := c.size_t(destination_value)
        mask := u64(1) << destination
        if weight == 0 do zero_edges[origin] |= mask
        else do one_edges[origin] |= mask
    }
    if output_capacity < vertices || output == nil do return -2

    head := c.size_t(0)
    tail := c.size_t(1)
    queued := c.size_t(1)
    deque[0] = u8(source)
    distance[source] = 0
    for queued != 0 {
        origin := c.size_t(deque[head])
        head = (head + 1) % 4097
        queued -= 1
        base := distance[origin]
        for destination: c.size_t = 0; destination < vertices; destination += 1 {
            mask := u64(1) << destination
            if (zero_edges[origin] & mask) != 0 && base < distance[destination] {
                distance[destination] = base
                if head == 0 do head = 4096
                else do head -= 1
                deque[head] = u8(destination)
                queued += 1
            }
            candidate := base + 1
            if (one_edges[origin] & mask) != 0 && candidate < distance[destination] {
                distance[destination] = candidate
                deque[tail] = u8(destination)
                tail = (tail + 1) % 4097
                queued += 1
            }
        }
    }

    for vertex: c.size_t = 0; vertex < vertices; vertex += 1 {
        output[vertex] = distance[vertex]
    }
    return i64(vertices)
}
