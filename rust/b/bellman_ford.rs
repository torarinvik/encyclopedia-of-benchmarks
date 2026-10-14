/// Directed edge triples, separate reachability, and checked distance addition.
#[no_mangle]
pub extern "C" fn bellman_ford(edges: *const i64, vertices: usize, edge_count: usize,
                              source: usize, distances: *mut i64, reachable: *mut u8) -> i64 {
    if vertices == 0 { return if source == 0 && edge_count == 0 { 0 } else { -3 }; }
    if source >= vertices { return -3; }
    // The caller supplies disjoint buffers with the documented element counts.
    let edges = if edge_count == 0 { &[] } else {
        unsafe { std::slice::from_raw_parts(edges, 3 * edge_count) }
    };
    for edge in edges.chunks_exact(3) {
        if edge[0] < 0 || edge[1] < 0 || edge[0] as u64 >= vertices as u64 ||
            edge[1] as u64 >= vertices as u64 { return -3; }
    }
    let distances = unsafe { std::slice::from_raw_parts_mut(distances, vertices) };
    let reachable = unsafe { std::slice::from_raw_parts_mut(reachable, vertices) };
    distances.fill(0);
    reachable.fill(0);
    reachable[source] = 1;
    for round in 0..vertices {
        let mut changed = false;
        for edge in edges.chunks_exact(3) {
            let origin = edge[0] as usize;
            let destination = edge[1] as usize;
            let weight = edge[2];
            if reachable[origin] == 0 { continue; }
            let base = distances[origin];
            if (weight > 0 && base > i64::MAX - weight) ||
                (weight < 0 && base < i64::MIN - weight) { return -2; }
            let candidate = base + weight;
            if reachable[destination] == 0 || candidate < distances[destination] {
                if round == vertices - 1 { return -1; }
                distances[destination] = candidate;
                reachable[destination] = 1;
                changed = true;
            }
        }
        if !changed { return 0; }
    }
    0
}
