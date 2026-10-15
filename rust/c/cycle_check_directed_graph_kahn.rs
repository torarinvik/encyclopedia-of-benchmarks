/// Directed cycle detection with Kahn's zero-indegree queue.
#[no_mangle]
pub unsafe extern "C" fn cycle_check_directed_graph_kahn(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > 65 || (length - 1) % 2 != 0 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if !(0..=64).contains(&values[0]) { return -1; }
    let vertices = values[0] as usize;
    let edge_count = (length - 1) / 2;
    if edge_count > 32 { return -1; }
    let mut adjacency = [0u64; 64];
    let mut indegree = [0usize; 64];
    for edge in 0..edge_count {
        let source = values[1 + 2 * edge];
        let destination = values[2 + 2 * edge];
        if source < 0 || destination < 0 || source as u64 >= vertices as u64 ||
            destination as u64 >= vertices as u64 { return -1; }
        let source = source as usize;
        let destination = destination as usize;
        let mask = 1u64 << destination;
        if adjacency[source] & mask == 0 {
            adjacency[source] |= mask;
            indegree[destination] += 1;
        }
    }
    let mut queue = [0usize; 64];
    let mut head = 0usize;
    let mut tail = 0usize;
    for vertex in 0..vertices {
        if indegree[vertex] == 0 {
            queue[tail] = vertex;
            tail += 1;
        }
    }
    let mut removed = 0usize;
    while head < tail {
        let source = queue[head];
        head += 1;
        removed += 1;
        for destination in 0..vertices {
            if adjacency[source] & (1u64 << destination) != 0 {
                indegree[destination] -= 1;
                if indegree[destination] == 0 {
                    queue[tail] = destination;
                    tail += 1;
                }
            }
        }
    }
    (removed != vertices) as i64
}
