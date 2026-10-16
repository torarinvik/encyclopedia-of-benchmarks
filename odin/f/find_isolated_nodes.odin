package find_isolated_nodes

import "core:c"

// Return vertices with no outgoing neighbors, in ascending vertex order.
@(export)
find_isolated_nodes :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || length > 65 || (length - 1) % 2 != 0 do return -2
    if values[0] < 0 || values[0] > 64 do return -2
    vertices := c.size_t(values[0])
    adjacency: [64]u64
    for vertex: c.size_t = 0; vertex < 64; vertex += 1 {
        adjacency[vertex] = 0
    }
    edge_count := (length - 1) / 2
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
    isolated: [64]u8
    count := c.size_t(0)
    for vertex: c.size_t = 0; vertex < vertices; vertex += 1 {
        if adjacency[vertex] == 0 {
            isolated[count] = u8(vertex)
            count += 1
        }
    }
    if output_capacity < count || (count != 0 && output == nil) do return -2
    for index: c.size_t = 0; index < count; index += 1 {
        output[index] = isolated[index]
    }
    return i64(count)
}
