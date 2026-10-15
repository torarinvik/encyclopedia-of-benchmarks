const MAX_VERTEX_COUNT: usize = 64;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGE_COUNT as usize;

fn visit_vertex(
    adjacency: &[u64; MAX_VERTEX_COUNT],
    vertex_count: usize,
    vertex: usize,
    discovery: &mut [i64; MAX_VERTEX_COUNT],
    low: &mut [i64; MAX_VERTEX_COUNT],
    parent: &mut [i64; MAX_VERTEX_COUNT],
    is_articulation: &mut [bool; MAX_VERTEX_COUNT],
    time: &mut usize,
) {
    discovery[vertex] = *time as i64;
    low[vertex] = *time as i64;
    *time += 1;
    let mut child_count = 0usize;
    for neighbor in 0..vertex_count {
        if adjacency[vertex] & (1u64 << neighbor) == 0 { continue; }
        if discovery[neighbor] == -1 {
            parent[neighbor] = vertex as i64;
            child_count += 1;
            visit_vertex(adjacency, vertex_count, neighbor, discovery, low, parent,
                         is_articulation, time);
            let child_low = low[neighbor];
            if child_low < low[vertex] { low[vertex] = child_low; }
            if parent[vertex] == -1 && child_count > 1 { is_articulation[vertex] = true; }
            if parent[vertex] != -1 && child_low >= discovery[vertex] { is_articulation[vertex] = true; }
        } else if neighbor as i64 != parent[vertex] && discovery[neighbor] < low[vertex] {
            low[vertex] = discovery[neighbor];
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn articulation_points(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let vertex_value = *input;
    let edge_value = *input.add(1);
    if !(0..=MAX_VERTEX_COUNT as i64).contains(&vertex_value) || !(0..=MAX_EDGE_COUNT).contains(&edge_value) {
        return -1;
    }
    let vertex_count = vertex_value as usize;
    let edge_count = edge_value as usize;
    if length != 2 + 2 * edge_count { return -1; }

    let mut adjacency = [0u64; MAX_VERTEX_COUNT];
    for edge in 0..edge_count {
        let left_value = *input.add(2 + 2 * edge);
        let right_value = *input.add(3 + 2 * edge);
        if left_value < 0 || right_value < 0 || left_value >= vertex_count as i64 ||
            right_value >= vertex_count as i64 { return -1; }
        let left = left_value as usize;
        let right = right_value as usize;
        adjacency[left] |= 1u64 << right;
        adjacency[right] |= 1u64 << left;
    }

    let mut discovery = [-1i64; MAX_VERTEX_COUNT];
    let mut low = [0i64; MAX_VERTEX_COUNT];
    let mut parent = [-1i64; MAX_VERTEX_COUNT];
    let mut is_articulation = [false; MAX_VERTEX_COUNT];
    let mut time = 0usize;
    for vertex in 0..vertex_count {
        if discovery[vertex] == -1 {
            visit_vertex(&adjacency, vertex_count, vertex, &mut discovery, &mut low,
                         &mut parent, &mut is_articulation, &mut time);
        }
    }
    let point_count = is_articulation[..vertex_count].iter().filter(|&&value| value).count();
    if output_capacity < point_count || (point_count != 0 && output.is_null()) { return -2; }
    let mut position = 0usize;
    for vertex in 0..vertex_count {
        if is_articulation[vertex] {
            *output.add(position) = vertex as u8;
            position += 1;
        }
    }
    point_count as i64
}
