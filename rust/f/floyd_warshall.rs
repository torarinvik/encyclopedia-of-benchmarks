/// Compute bounded all-pairs shortest paths and return one source row.
const MAX_VERTICES: usize = 64;
const FLOYD_STORAGE: usize = MAX_VERTICES * MAX_VERTICES;

#[no_mangle]
pub unsafe extern "C" fn floyd_warshall(edges: *const i64, vertices: usize, edge_count: usize,
                                          source: usize, distances: *mut i64,
                                          reachable: *mut u8) -> i64 {
    if vertices == 0 { return if source == 0 && edge_count == 0 { 0 } else { -3 }; }
    if vertices > MAX_VERTICES || source >= vertices { return -3; }
    for edge in 0..edge_count {
        let origin = *edges.add(3 * edge);
        let destination = *edges.add(3 * edge + 1);
        if origin < 0 || destination < 0 || origin as u64 >= vertices as u64 ||
            destination as u64 >= vertices as u64 { return -3; }
    }
    let mut all_distances = [0i64; FLOYD_STORAGE];
    let mut present = [0u8; FLOYD_STORAGE];
    for vertex in 0..vertices { present[vertex * vertices + vertex] = 1; }
    for edge in 0..edge_count {
        let origin = *edges.add(3 * edge) as usize;
        let destination = *edges.add(3 * edge + 1) as usize;
        let index = origin * vertices + destination;
        let weight = *edges.add(3 * edge + 2);
        if present[index] == 0 || weight < all_distances[index] {
            all_distances[index] = weight;
            present[index] = 1;
        }
    }
    for middle in 0..vertices {
        for origin in 0..vertices {
            let left_index = origin * vertices + middle;
            if present[left_index] == 0 { continue; }
            for destination in 0..vertices {
                let right_index = middle * vertices + destination;
                if present[right_index] == 0 { continue; }
                let left = all_distances[left_index];
                let right = all_distances[right_index];
                if (right > 0 && left > i64::MAX - right) ||
                    (right < 0 && left < i64::MIN - right) { return -2; }
                let candidate = left + right;
                let index = origin * vertices + destination;
                if present[index] == 0 || candidate < all_distances[index] {
                    all_distances[index] = candidate;
                    present[index] = 1;
                }
            }
        }
    }
    for vertex in 0..vertices {
        let index = source * vertices + vertex;
        if present[index] != 0 && present[vertex * vertices + vertex] != 0 &&
            all_distances[vertex * vertices + vertex] < 0 { return -1; }
    }
    for vertex in 0..vertices {
        let index = source * vertices + vertex;
        *reachable.add(vertex) = present[index];
        *distances.add(vertex) = if present[index] != 0 { all_distances[index] } else { 0 };
    }
    0
}
