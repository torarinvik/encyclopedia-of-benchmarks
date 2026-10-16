const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 4 + 2 * MAX_EDGES;
const MAX_OUTPUT_VALUES: usize = 1 + MAX_VERTICES;

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn breadth_first_search_shortest_path(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let (vertex_value, edge_value, start_value, goal_value) = (values[0], values[1], values[2], values[3]);
    if !(1..=MAX_VERTICES as i64).contains(&vertex_value) || !(0..=MAX_EDGES as i64).contains(&edge_value) { return -1; }
    let vertices = vertex_value as usize;
    let edges = edge_value as usize;
    if length != 4 + 2 * edges || start_value < 0 || start_value >= vertices as i64 || goal_value < 0 || goal_value >= vertices as i64 { return -1; }
    let mut adjacency = [[0usize; MAX_EDGES]; MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    for edge in 0..edges {
        let from = values[4 + 2 * edge];
        let to = values[5 + 2 * edge];
        if from < 0 || from >= vertices as i64 || to < 0 || to >= vertices as i64 { return -1; }
        let source = from as usize;
        adjacency[source][degree[source]] = to as usize;
        degree[source] += 1;
    }
    let start = start_value as usize;
    let goal = goal_value as usize;
    let mut parent = [-1i64; MAX_VERTICES];
    let mut visited = [false; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let (mut head, mut tail) = (0usize, 0usize);
    visited[start] = true;
    queue[tail] = start;
    tail += 1;
    while head < tail && !visited[goal] {
        let node = queue[head];
        head += 1;
        for index in 0..degree[node] {
            let neighbor = adjacency[node][index];
            if visited[neighbor] { continue; }
            visited[neighbor] = true;
            parent[neighbor] = node as i64;
            queue[tail] = neighbor;
            tail += 1;
            if neighbor == goal { break; }
        }
    }
    let mut encoded = [0i64; MAX_OUTPUT_VALUES];
    let mut path_count = 0usize;
    if visited[goal] {
        let mut reverse_path = [0usize; MAX_VERTICES];
        let mut current = goal as i64;
        while current >= 0 {
            reverse_path[path_count] = current as usize;
            path_count += 1;
            if current as usize == start { break; }
            current = parent[current as usize];
        }
        for index in 0..path_count { encoded[1 + index] = reverse_path[path_count - 1 - index] as i64; }
    }
    encoded[0] = path_count as i64;
    let required = (path_count + 1) * 8;
    if output.is_null() || capacity < required { return -2; }
    let out = unsafe { core::slice::from_raw_parts_mut(output, required) };
    for index in 0..=path_count { put_i64(out, index * 8, encoded[index]); }
    required as i64
}
