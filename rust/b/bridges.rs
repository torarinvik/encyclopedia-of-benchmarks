const MAX_VERTEX_COUNT: usize = 64;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGE_COUNT as usize;

fn visit_vertex(
    adjacency: &[u64; MAX_VERTEX_COUNT],
    bridges: &mut [u64; MAX_VERTEX_COUNT],
    vertex_count: usize,
    vertex: usize,
    discovery: &mut [i64; MAX_VERTEX_COUNT],
    low: &mut [i64; MAX_VERTEX_COUNT],
    parent: &mut [i64; MAX_VERTEX_COUNT],
    time: &mut usize,
) {
    discovery[vertex] = *time as i64;
    low[vertex] = *time as i64;
    *time += 1;
    for neighbor in 0..vertex_count {
        if adjacency[vertex] & (1u64 << neighbor) == 0 { continue; }
        if discovery[neighbor] == -1 {
            parent[neighbor] = vertex as i64;
            visit_vertex(adjacency, bridges, vertex_count, neighbor, discovery, low, parent, time);
            if low[neighbor] < low[vertex] { low[vertex] = low[neighbor]; }
            if low[neighbor] > discovery[vertex] {
                bridges[vertex] |= 1u64 << neighbor;
                bridges[neighbor] |= 1u64 << vertex;
            }
        } else if neighbor as i64 != parent[vertex] && discovery[neighbor] < low[vertex] {
            low[vertex] = discovery[neighbor];
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn bridges(
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
    let mut bridge_mask = [0u64; MAX_VERTEX_COUNT];
    let mut time = 0usize;
    for vertex in 0..vertex_count {
        if discovery[vertex] == -1 {
            visit_vertex(&adjacency, &mut bridge_mask, vertex_count, vertex,
                         &mut discovery, &mut low, &mut parent, &mut time);
        }
    }
    let mut bridge_count = 0usize;
    for left in 0..vertex_count {
        for right in (left + 1)..vertex_count {
            if bridge_mask[left] & (1u64 << right) != 0 { bridge_count += 1; }
        }
    }
    let output_length = 2 * bridge_count;
    if output_capacity < output_length || (output_length != 0 && output.is_null()) { return -2; }
    let mut position = 0usize;
    for left in 0..vertex_count {
        for right in (left + 1)..vertex_count {
            if bridge_mask[left] & (1u64 << right) != 0 {
                *output.add(position) = left as u8;
                *output.add(position + 1) = right as u8;
                position += 2;
            }
        }
    }
    output_length as i64
}
