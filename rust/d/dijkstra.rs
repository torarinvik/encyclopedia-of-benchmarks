/// Directed edge triples, nonnegative weights, separate reachability.
#[no_mangle]
pub extern "C" fn dijkstra(edges: *const i64, vertices: usize, edge_count: usize,
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
        if edge[2] < 0 { return -4; }
    }
    let distances = unsafe { std::slice::from_raw_parts_mut(distances, vertices) };
    let reachable = unsafe { std::slice::from_raw_parts_mut(reachable, vertices) };
    distances.fill(0);
    reachable.fill(0);
    reachable[source] = 1;
    for _ in 0..vertices {
        let mut selected = vertices;
        let mut best = 0i64;
        for vertex in 0..vertices {
            if reachable[vertex] == 1 && (selected == vertices || distances[vertex] < best) {
                selected = vertex;
                best = distances[vertex];
            }
        }
        if selected == vertices { break; }
        reachable[selected] = 2;
        for edge in edges.chunks_exact(3) {
            if edge[0] as usize != selected { continue; }
            let destination = edge[1] as usize;
            let weight = edge[2];
            let base = distances[selected];
            if base > i64::MAX - weight { return -2; }
            let candidate = base + weight;
            if reachable[destination] != 2 &&
                (reachable[destination] == 0 || candidate < distances[destination]) {
                distances[destination] = candidate;
                reachable[destination] = 1;
            }
        }
    }
    for flag in reachable.iter_mut() { if *flag == 2 { *flag = 1; } }
    0
}
