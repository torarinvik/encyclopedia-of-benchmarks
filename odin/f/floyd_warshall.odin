package floyd_warshall

import "core:c"

@(export)
floyd_warshall :: proc "c" (edges: [^]i64, vertices, edge_count, source: c.size_t,
        distances: [^]i64, reachable: [^]u8) -> i64 {
    if vertices == 0 {
        if source == 0 && edge_count == 0 do return 0
        return -3
    }
    if vertices > 64 || source >= vertices do return -3
    for edge := c.size_t(0); edge < edge_count; edge += 1 {
        origin := edges[3 * edge]
        destination := edges[3 * edge + 1]
        if origin < 0 || destination < 0 || u64(origin) >= u64(vertices) || u64(destination) >= u64(vertices) do return -3
    }
    all_distances: [4096]i64
    present: [4096]u8
    for vertex := c.size_t(0); vertex < vertices; vertex += 1 {
        present[vertex * vertices + vertex] = 1
    }
    for edge := c.size_t(0); edge < edge_count; edge += 1 {
        origin := c.size_t(edges[3 * edge])
        destination := c.size_t(edges[3 * edge + 1])
        index := origin * vertices + destination
        weight := edges[3 * edge + 2]
        if present[index] == 0 || weight < all_distances[index] {
            all_distances[index] = weight
            present[index] = 1
        }
    }
    for middle := c.size_t(0); middle < vertices; middle += 1 {
        for origin := c.size_t(0); origin < vertices; origin += 1 {
            left_index := origin * vertices + middle
            if present[left_index] == 0 do continue
            for destination := c.size_t(0); destination < vertices; destination += 1 {
                right_index := middle * vertices + destination
                if present[right_index] == 0 do continue
                left, right := all_distances[left_index], all_distances[right_index]
                if (right > 0 && left > i64(9223372036854775807) - right) ||
                   (right < 0 && left < (i64(-9223372036854775807) - 1) - right) {
                    return -2
                }
                candidate := left + right
                index := origin * vertices + destination
                if present[index] == 0 || candidate < all_distances[index] {
                    all_distances[index] = candidate
                    present[index] = 1
                }
            }
        }
    }
    for vertex := c.size_t(0); vertex < vertices; vertex += 1 {
        index := source * vertices + vertex
        diagonal := vertex * vertices + vertex
        if present[index] != 0 && present[diagonal] != 0 && all_distances[diagonal] < 0 do return -1
    }
    for vertex := c.size_t(0); vertex < vertices; vertex += 1 {
        index := source * vertices + vertex
        reachable[vertex] = present[index]
        if present[index] != 0 { distances[vertex] = all_distances[index] }
        else { distances[vertex] = 0 }
    }
    return 0
}
