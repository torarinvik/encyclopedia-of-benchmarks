/// Recursive reachability search in a bounded undirected graph.
const MAX_VERTICES: usize = 64;
const MAX_EDGES: i64 = 256;
const MAX_INPUT_LENGTH: usize = 518;
const ADJACENCY_CAPACITY: usize = MAX_VERTICES * MAX_VERTICES;

fn reachable(adjacency: &[usize; ADJACENCY_CAPACITY], degree: &[usize; MAX_VERTICES],
             current: usize, target: i64, visited: &mut [bool; MAX_VERTICES]) -> bool {
    if current as i64 == target { return true; }
    visited[current] = true;
    for position in 0..degree[current] {
        let neighbor = adjacency[current * MAX_VERTICES + position];
        if !visited[neighbor] && reachable(adjacency, degree, neighbor, target, visited) { return true; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn depth_first_search_recursive(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let vertex_count = values[0];
    let edge_count_value = values[1];
    let source = values[2];
    let target = values[3];
    if vertex_count < 1 || vertex_count > MAX_VERTICES as i64 || edge_count_value < 0
        || edge_count_value > MAX_EDGES || source < 0 || source >= vertex_count { return -1; }
    let edge_count = edge_count_value as usize;
    if length != 4 + 2 * edge_count { return -1; }
    for edge in 0..edge_count {
        let left = values[4 + 2 * edge];
        let right = values[5 + 2 * edge];
        if left < 0 || left >= vertex_count || right < 0 || right >= vertex_count { return -1; }
    }

    let mut adjacency = [0usize; ADJACENCY_CAPACITY];
    let mut degree = [0usize; MAX_VERTICES];
    let mut seen = [0_u64; MAX_VERTICES];
    for edge in 0..edge_count {
        let left = values[4 + 2 * edge] as usize;
        let right = values[5 + 2 * edge] as usize;
        let right_bit = 1_u64 << right;
        if seen[left] & right_bit == 0 {
            seen[left] |= right_bit;
            adjacency[left * MAX_VERTICES + degree[left]] = right;
            degree[left] += 1;
        }
        let left_bit = 1_u64 << left;
        if seen[right] & left_bit == 0 {
            seen[right] |= left_bit;
            adjacency[right * MAX_VERTICES + degree[right]] = left;
            degree[right] += 1;
        }
    }
    let mut visited = [false; MAX_VERTICES];
    if reachable(&adjacency, &degree, source as usize, target, &mut visited) { 1 } else { 0 }
}
