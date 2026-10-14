module floyd_warshall

const max_vertices = 64
const floyd_storage = max_vertices * max_vertices

// Compute bounded all-pairs shortest paths and return one source row.
@[export: 'floyd_warshall']
pub fn floyd_warshall(edges &i64, vertices usize, edge_count usize, source usize,
                      mut distances &i64, mut reachable &u8) i64 {
    if vertices == 0 { return if source == 0 && edge_count == 0 { i64(0) } else { i64(-3) } }
    if vertices > max_vertices || source >= vertices { return -3 }
    for edge := usize(0); edge < edge_count; edge++ {
        origin := unsafe { edges[3 * edge] }
        destination := unsafe { edges[3 * edge + 1] }
        if origin < 0 || destination < 0 || u64(origin) >= u64(vertices) || u64(destination) >= u64(vertices) { return -3 }
    }
    mut all_distances := [floyd_storage]i64{}
    mut present := [floyd_storage]u8{}
    for vertex := usize(0); vertex < vertices; vertex++ {
        present[vertex * vertices + vertex] = 1
    }
    for edge := usize(0); edge < edge_count; edge++ {
        origin := usize(unsafe { edges[3 * edge] })
        destination := usize(unsafe { edges[3 * edge + 1] })
        index := origin * vertices + destination
        weight := unsafe { edges[3 * edge + 2] }
        if present[index] == 0 || weight < all_distances[index] {
            all_distances[index] = weight
            present[index] = 1
        }
    }
    for middle := usize(0); middle < vertices; middle++ {
        for origin := usize(0); origin < vertices; origin++ {
            left_index := origin * vertices + middle
            if present[left_index] == 0 { continue }
            for destination := usize(0); destination < vertices; destination++ {
                right_index := middle * vertices + destination
                if present[right_index] == 0 { continue }
                left := all_distances[left_index]
                right := all_distances[right_index]
                if (right > 0 && left > i64(9223372036854775807) - right) ||
                   (right < 0 && left < (i64(-9223372036854775807) - 1) - right) { return -2 }
                candidate := left + right
                index := origin * vertices + destination
                if present[index] == 0 || candidate < all_distances[index] {
                    all_distances[index] = candidate
                    present[index] = 1
                }
            }
        }
    }
    for vertex := usize(0); vertex < vertices; vertex++ {
        index := source * vertices + vertex
        diagonal := vertex * vertices + vertex
        if present[index] != 0 && present[diagonal] != 0 && all_distances[diagonal] < 0 { return -1 }
    }
    for vertex := usize(0); vertex < vertices; vertex++ {
        index := source * vertices + vertex
        unsafe {
            reachable[vertex] = present[index]
            distances[vertex] = if present[index] != 0 { all_distances[index] } else { i64(0) }
        }
    }
    return 0
}
