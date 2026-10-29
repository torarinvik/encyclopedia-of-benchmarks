const MAX_VERTICES: usize = 6;
const MAX_EDGES: usize = 12;
const MAX_K: usize = 8;
const MAX_INPUT_LENGTH: usize = 41;
const MAX_FRONTIER: usize = 97;

fn write_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn k_shortest_walk(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let m_value = values[1];
    let source_value = values[2];
    let target_value = values[3];
    let k_value = values[4];
    if n_value < 1 || n_value > MAX_VERTICES as i64 ||
        m_value < 0 || m_value > MAX_EDGES as i64 ||
        k_value < 1 || k_value > MAX_K as i64 ||
        source_value < 0 || source_value >= n_value || target_value < 0 || target_value >= n_value {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    let source = source_value as usize;
    let target = target_value as usize;
    let k = k_value as usize;
    if length != 5 + 3 * m {
        return -1;
    }

    let mut head = [-1_i64; MAX_VERTICES];
    let mut edge_to = [0_i64; MAX_EDGES];
    let mut edge_weight = [0_i64; MAX_EDGES];
    let mut edge_next = [0_i64; MAX_EDGES];
    for edge in 0..m {
        let u = values[5 + 3 * edge];
        let v = values[6 + 3 * edge];
        let weight = values[7 + 3 * edge];
        if u < 0 || u >= n_value || v < 0 || v >= n_value || weight < 0 || weight > 1000 {
            return -1;
        }
        let source_vertex = u as usize;
        edge_to[edge] = v;
        edge_weight[edge] = weight;
        edge_next[edge] = head[source_vertex];
        head[source_vertex] = edge as i64;
    }
    if output.is_null() || output_capacity < 8 * k {
        return -2;
    }

    let mut queue_distance = [0_i64; MAX_FRONTIER];
    let mut queue_vertex = [0_i64; MAX_FRONTIER];
    let mut queue_order = [0_i64; MAX_FRONTIER];
    let mut expanded = [0_i64; MAX_VERTICES];
    let mut answers = [0_i64; MAX_K];
    let mut queue_count = 1_usize;
    let mut answer_count = 0_usize;
    let mut next_order = 1_i64;
    queue_distance[0] = 0;
    queue_vertex[0] = source as i64;
    queue_order[0] = 0;

    while queue_count > 0 && answer_count < k {
        let distance = queue_distance[0];
        let vertex = queue_vertex[0] as usize;
        for slot in 1..queue_count {
            queue_distance[slot - 1] = queue_distance[slot];
            queue_vertex[slot - 1] = queue_vertex[slot];
            queue_order[slot - 1] = queue_order[slot];
        }
        queue_count -= 1;
        if expanded[vertex] >= k as i64 {
            continue;
        }
        expanded[vertex] += 1;
        if vertex == target {
            answers[answer_count] = distance;
            answer_count += 1;
            if answer_count == k {
                break;
            }
        }
        let mut edge = head[vertex];
        while edge >= 0 {
            let edge_index = edge as usize;
            let candidate_distance = distance + edge_weight[edge_index];
            let candidate_vertex = edge_to[edge_index];
            let candidate_order = next_order;
            next_order += 1;
            let mut position = queue_count;
            while position > 0 &&
                (queue_distance[position - 1] > candidate_distance ||
                 (queue_distance[position - 1] == candidate_distance && queue_order[position - 1] > candidate_order)) {
                queue_distance[position] = queue_distance[position - 1];
                queue_vertex[position] = queue_vertex[position - 1];
                queue_order[position] = queue_order[position - 1];
                position -= 1;
            }
            queue_distance[position] = candidate_distance;
            queue_vertex[position] = candidate_vertex;
            queue_order[position] = candidate_order;
            queue_count += 1;
            edge = edge_next[edge_index];
        }
    }
    while answer_count < k {
        answers[answer_count] = -1;
        answer_count += 1;
    }
    for index in 0..k {
        write_i64(output, 8 * index, answers[index]);
    }
    (8 * k) as i64
}
