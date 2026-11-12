/// Minimum edge coloring of a bounded bipartite multigraph.
const MAX_SIDE: usize = 5;
const MAX_EDGES: usize = 10;
const MAX_INPUT_LENGTH: usize = 23;
const MAX_OUTPUT_BYTES: usize = 88;

fn augment(left: usize, side: usize, multiplicity: &[i64; MAX_SIDE * MAX_SIDE],
           seen: &mut [bool; MAX_SIDE], match_right: &mut [i32; MAX_SIDE]) -> bool {
    for right in 0..side {
        let index = left * MAX_SIDE + right;
        if multiplicity[index] == 0 || seen[right] { continue; }
        seen[right] = true;
        let mate = match_right[right];
        if mate < 0 || augment(mate as usize, side, multiplicity, seen, match_right) {
            match_right[right] = left as i32;
            return true;
        }
    }
    false
}

fn store_u64_le(output: &mut [u8; MAX_OUTPUT_BYTES], offset: usize, value: u64) {
    for byte in 0..8 { output[offset + byte] = ((value >> (byte * 8)) & 0xff) as u8; }
}

/// Packed input `[L, R, M, (left, right)*M]`; writes `[K, colors...]` as LE u64s.
#[no_mangle]
pub unsafe extern "C" fn bipartite_edge_coloring(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let left_value = values[0];
    let right_value = values[1];
    let edge_value = values[2];
    if !(1..=MAX_SIDE as i64).contains(&left_value)
        || !(1..=MAX_SIDE as i64).contains(&right_value)
        || !(1..=MAX_EDGES as i64).contains(&edge_value) { return -1; }
    let left_count = left_value as usize;
    let right_count = right_value as usize;
    let edge_count = edge_value as usize;
    if length != 3 + 2 * edge_count { return -1; }

    let mut multiplicity = [0i64; MAX_SIDE * MAX_SIDE];
    let mut original_remaining = [0i64; MAX_SIDE * MAX_SIDE];
    let mut left_degree = [0usize; MAX_SIDE];
    let mut right_degree = [0usize; MAX_SIDE];
    let mut edge_left = [0usize; MAX_EDGES];
    let mut edge_right = [0usize; MAX_EDGES];
    for edge in 0..edge_count {
        let left = values[3 + 2 * edge];
        let right = values[4 + 2 * edge];
        if left < 0 || left >= left_value || right < 0 || right >= right_value { return -1; }
        let u = left as usize;
        let v = right as usize;
        edge_left[edge] = u;
        edge_right[edge] = v;
        let index = u * MAX_SIDE + v;
        multiplicity[index] += 1;
        original_remaining[index] += 1;
        left_degree[u] += 1;
        right_degree[v] += 1;
    }

    let side = left_count.max(right_count);
    let mut maximum_degree = 0usize;
    for vertex in 0..side {
        maximum_degree = maximum_degree.max(left_degree[vertex]).max(right_degree[vertex]);
    }
    loop {
        let mut left = 0;
        while left < side && left_degree[left] == maximum_degree { left += 1; }
        if left == side { break; }
        let mut right = 0;
        while right < side && right_degree[right] == maximum_degree { right += 1; }
        if right == side { return -1; }
        multiplicity[left * MAX_SIDE + right] += 1;
        left_degree[left] += 1;
        right_degree[right] += 1;
    }

    let mut colors = [-1i64; MAX_EDGES];
    for color in 0..maximum_degree {
        let mut match_right = [-1i32; MAX_SIDE];
        for left in 0..side {
            let mut seen = [false; MAX_SIDE];
            if !augment(left, side, &multiplicity, &mut seen, &mut match_right) { return -1; }
        }
        for right in 0..side {
            let left = match_right[right];
            if left < 0 { return -1; }
            let left = left as usize;
            let index = left * MAX_SIDE + right;
            if original_remaining[index] > 0 {
                let mut edge = 0;
                while edge < edge_count &&
                    (colors[edge] >= 0 || edge_left[edge] != left || edge_right[edge] != right) {
                    edge += 1;
                }
                if edge == edge_count { return -1; }
                colors[edge] = color as i64;
                original_remaining[index] -= 1;
            }
            multiplicity[index] -= 1;
        }
    }

    let bytes = 8 * (edge_count + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    store_u64_le(&mut staged, 0, maximum_degree as u64);
    for edge in 0..edge_count { store_u64_le(&mut staged, 8 * (edge + 1), colors[edge] as u64); }
    let result = std::slice::from_raw_parts_mut(output, bytes);
    result.copy_from_slice(&staged[..bytes]);
    bytes as i64
}
