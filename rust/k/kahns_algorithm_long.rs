const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 128;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;

#[no_mangle]
pub extern "C" fn kahns_algorithm_long(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let vertex_count = values[0];
    let edge_count = values[1];
    if !(1..=MAX_VERTICES as i64).contains(&vertex_count)
        || !(0..=MAX_EDGES as i64).contains(&edge_count)
        || length != (2 + 2 * edge_count as usize) { return -1; }

    let mut multiplicity = [0_i64; MAX_VERTICES * MAX_VERTICES];
    let mut indegree = [0_i64; MAX_VERTICES];
    let mut distance = [0_i64; MAX_VERTICES];
    let mut queue = [0_usize; MAX_VERTICES];
    for value in &mut distance[..vertex_count as usize] { *value = 1; }
    for edge in 0..edge_count as usize {
        let source = values[2 + 2 * edge];
        let destination = values[3 + 2 * edge];
        if source < 0 || source >= vertex_count || destination < 0 || destination >= vertex_count { return -1; }
        let source = source as usize;
        let destination = destination as usize;
        multiplicity[source * MAX_VERTICES + destination] += 1;
        indegree[destination] += 1;
    }

    let mut head = 0;
    let mut tail = 0;
    for vertex in 0..vertex_count as usize {
        if indegree[vertex] == 0 { queue[tail] = vertex; tail += 1; }
    }
    let mut processed = 0_i64;
    let mut maximum = 1_i64;
    while head < tail {
        let source = queue[head];
        head += 1;
        processed += 1;
        maximum = maximum.max(distance[source]);
        for destination in 0..vertex_count as usize {
            let copies = multiplicity[source * MAX_VERTICES + destination];
            if copies == 0 { continue; }
            distance[destination] = distance[destination].max(distance[source] + 1);
            for _ in 0..copies {
                indegree[destination] -= 1;
                if indegree[destination] == 0 { queue[tail] = destination; tail += 1; }
            }
        }
    }
    if processed != vertex_count { return -1; }
    for &value in &distance[..vertex_count as usize] { maximum = maximum.max(value); }
    maximum
}
