const MAX_VERTICES: usize = 64;
const MAX_INPUT_EDGES: usize = 256;
const MAX_NORMALIZED_EDGES: usize = 128;
const MAX_WEIGHT: i64 = 1_000;
const RECORD_BYTES: usize = 24;

unsafe fn write_record(output: *mut u8, capacity: usize, status: i64, reachable: i64, distance: i64) -> i64 {
    if output.is_null() || capacity < RECORD_BYTES {
        return -2;
    }
    for (field, value) in [status, reachable, distance].iter().enumerate() {
        let bytes = value.to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(field * 8), 8);
    }
    RECORD_BYTES as i64
}

#[no_mangle]
pub unsafe extern "C" fn bellman_ford_pair(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let vertices_value = input[0];
    let input_edges_value = input[1];
    let source_value = input[2];
    let target_value = input[3];
    if vertices_value < 1 || vertices_value > MAX_VERTICES as i64
        || input_edges_value < 0 || input_edges_value > MAX_INPUT_EDGES as i64
    {
        return -1;
    }
    let vertices = vertices_value as usize;
    let input_edges = input_edges_value as usize;
    if source_value < 0 || source_value >= vertices_value || target_value < 0 || target_value >= vertices_value
        || length != 4 + 3 * input_edges
    {
        return -1;
    }

    let mut matrix_weights = [0_i64; MAX_VERTICES * MAX_VERTICES];
    let mut matrix_present = [false; MAX_VERTICES * MAX_VERTICES];
    let mut normalized_count = 0;
    for edge in 0..input_edges {
        let from_value = input[4 + 3 * edge];
        let to_value = input[5 + 3 * edge];
        let weight = input[6 + 3 * edge];
        if from_value < 0 || from_value >= vertices_value || to_value < 0 || to_value >= vertices_value
            || weight < -MAX_WEIGHT || weight > MAX_WEIGHT
        {
            return -1;
        }
        let key = from_value as usize * vertices + to_value as usize;
        if !matrix_present[key] {
            matrix_present[key] = true;
            normalized_count += 1;
            if normalized_count > MAX_NORMALIZED_EDGES {
                return -1;
            }
        }
        matrix_weights[key] = weight;
    }

    let mut from = [0_usize; MAX_NORMALIZED_EDGES];
    let mut to = [0_usize; MAX_NORMALIZED_EDGES];
    let mut weight = [0_i64; MAX_NORMALIZED_EDGES];
    let mut edge_count = 0;
    for origin in 0..vertices {
        for destination in 0..vertices {
            let key = origin * vertices + destination;
            if !matrix_present[key] {
                continue;
            }
            from[edge_count] = origin;
            to[edge_count] = destination;
            weight[edge_count] = matrix_weights[key];
            edge_count += 1;
        }
    }

    let source = source_value as usize;
    let target = target_value as usize;
    let mut distance = [0_i64; MAX_VERTICES];
    let mut reachable = [false; MAX_VERTICES];
    reachable[source] = true;
    for _ in 0..vertices {
        let mut changed = false;
        for edge in 0..edge_count {
            if !reachable[from[edge]] {
                continue;
            }
            let candidate = distance[from[edge]] + weight[edge];
            if !reachable[to[edge]] || candidate < distance[to[edge]] {
                distance[to[edge]] = candidate;
                reachable[to[edge]] = true;
                changed = true;
            }
        }
        if !changed {
            break;
        }
    }
    for edge in 0..edge_count {
        if reachable[from[edge]] && distance[to[edge]] > distance[from[edge]] + weight[edge] {
            return write_record(output, capacity, -1, 0, 0);
        }
    }
    let target_reachable = reachable[target];
    write_record(output, capacity, 0, if target_reachable { 1 } else { 0 }, if target_reachable { distance[target] } else { 0 })
}
