const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_HEAP: usize = MAX_EDGES + 1;
const NONE: usize = MAX_EDGES;

fn before(left_distance: i64, left_vertex: usize, right_distance: i64, right_vertex: usize) -> bool {
    left_distance < right_distance || (left_distance == right_distance && left_vertex < right_vertex)
}

fn push(heap_distance: &mut [i64; MAX_HEAP], heap_vertex: &mut [usize; MAX_HEAP],
        count: &mut usize, distance: i64, vertex: usize) {
    let mut position = *count;
    *count += 1;
    while position > 0 {
        let parent = (position - 1) / 2;
        if !before(distance, vertex, heap_distance[parent], heap_vertex[parent]) { break; }
        heap_distance[position] = heap_distance[parent];
        heap_vertex[position] = heap_vertex[parent];
        position = parent;
    }
    heap_distance[position] = distance;
    heap_vertex[position] = vertex;
}

fn pop(heap_distance: &mut [i64; MAX_HEAP], heap_vertex: &mut [usize; MAX_HEAP],
       count: &mut usize) -> (i64, usize) {
    let result = (heap_distance[0], heap_vertex[0]);
    *count -= 1;
    if *count > 0 {
        let last_distance = heap_distance[*count];
        let last_vertex = heap_vertex[*count];
        let mut position = 0;
        while 2 * position + 1 < *count {
            let mut child = 2 * position + 1;
            if child + 1 < *count && before(heap_distance[child + 1], heap_vertex[child + 1],
                                           heap_distance[child], heap_vertex[child]) { child += 1; }
            if !before(heap_distance[child], heap_vertex[child], last_distance, last_vertex) { break; }
            heap_distance[position] = heap_distance[child];
            heap_vertex[position] = heap_vertex[child];
            position = child;
        }
        heap_distance[position] = last_distance;
        heap_vertex[position] = last_vertex;
    }
    result
}

fn execute(edges: &[i64], vertices: usize, edge_count: usize, source: usize,
           distances: &mut [i64], reachable: &mut [u8]) -> i64 {
    if vertices > MAX_VERTICES || edge_count > MAX_EDGES { return -3; }
    if vertices == 0 { return if source == 0 && edge_count == 0 { 0 } else { -3 }; }
    if source >= vertices { return -3; }
    for edge in edges.chunks_exact(3) {
        if edge[0] < 0 || edge[1] < 0 || edge[0] as u64 >= vertices as u64 ||
            edge[1] as u64 >= vertices as u64 { return -3; }
        if edge[2] < 0 { return -4; }
    }

    let mut head = [NONE; MAX_VERTICES];
    let mut tail = [NONE; MAX_VERTICES];
    let mut next = [NONE; MAX_EDGES];
    for edge_index in 0..edge_count {
        let origin = edges[3 * edge_index] as usize;
        if head[origin] == NONE { head[origin] = edge_index; }
        else { next[tail[origin]] = edge_index; }
        tail[origin] = edge_index;
    }

    for vertex in 0..vertices { distances[vertex] = 0; reachable[vertex] = 0; }
    let mut heap_distance = [0i64; MAX_HEAP];
    let mut heap_vertex = [0usize; MAX_HEAP];
    let mut heap_count = 0;
    distances[source] = 0;
    reachable[source] = 1;
    push(&mut heap_distance, &mut heap_vertex, &mut heap_count, 0, source);

    while heap_count > 0 {
        let (current, origin) = pop(&mut heap_distance, &mut heap_vertex, &mut heap_count);
        if current != distances[origin] || reachable[origin] == 2 { continue; }
        reachable[origin] = 2;
        let mut edge_index = head[origin];
        while edge_index != NONE {
            let destination = edges[3 * edge_index + 1] as usize;
            let weight = edges[3 * edge_index + 2];
            if current > i64::MAX - weight { return -2; }
            let candidate = current + weight;
            if reachable[destination] != 2 &&
                (reachable[destination] == 0 || candidate < distances[destination]) {
                distances[destination] = candidate;
                reachable[destination] = 1;
                push(&mut heap_distance, &mut heap_vertex, &mut heap_count, candidate, destination);
            }
            edge_index = next[edge_index];
        }
    }
    for flag in reachable.iter_mut().take(vertices) { if *flag == 2 { *flag = 1; } }
    0
}

#[no_mangle]
pub unsafe extern "C" fn dijkstra_lazy_heap(edges: *const i64, vertices: usize,
                                             edge_count: usize, source: usize,
                                             distances: *mut i64, reachable: *mut u8) -> i64 {
    if vertices > MAX_VERTICES || edge_count > MAX_EDGES { return -3; }
    if vertices == 0 { return if source == 0 && edge_count == 0 { 0 } else { -3 }; }
    if source >= vertices { return -3; }
    if edge_count > 0 && edges.is_null() { return -3; }
    if distances.is_null() || reachable.is_null() { return -3; }
    let edge_slice = if edge_count == 0 { &[] } else {
        unsafe { std::slice::from_raw_parts(edges, 3 * edge_count) }
    };
    let distance_slice = unsafe { std::slice::from_raw_parts_mut(distances, vertices) };
    let reachable_slice = unsafe { std::slice::from_raw_parts_mut(reachable, vertices) };
    execute(edge_slice, vertices, edge_count, source, distance_slice, reachable_slice)
}
