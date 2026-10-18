const MAX_INITIAL_NODES: usize = 12;
const MAX_OPERATIONS: usize = 16;
const MAX_KNOWN_IDS: usize = MAX_INITIAL_NODES + 2 * MAX_OPERATIONS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 64;
const MAX_OUTPUT_WORDS: usize = 81;
const MAX_OUTPUT_BYTES: usize = 648;

fn find_id(ids: &[i64; MAX_KNOWN_IDS], count: usize, id: i64) -> Option<usize> {
    (0..count).find(|&index| ids[index] == id)
}

fn ensure_id(
    ids: &mut [i64; MAX_KNOWN_IDS],
    declared: &mut [bool; MAX_KNOWN_IDS],
    count: &mut usize,
    id: i64,
) -> Option<usize> {
    if let Some(found) = find_id(ids, *count, id) {
        return Some(found);
    }
    if *count >= MAX_KNOWN_IDS {
        return None;
    }
    let index = *count;
    *count += 1;
    ids[index] = id;
    declared[index] = false;
    Some(index)
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn unweighted_graph(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, input_length);
    if (values[0] != 0 && values[0] != 1)
        || values[1] < 0
        || values[1] > MAX_INITIAL_NODES as i64
        || values[2] < 0
        || values[2] > MAX_OPERATIONS as i64
    {
        return -1;
    }
    let directed = values[0] == 1;
    let initial_count = values[1] as usize;
    let operation_count = values[2] as usize;
    if input_length != 3 + initial_count + operation_count * 3 {
        return -1;
    }

    let mut ids = [0_i64; MAX_KNOWN_IDS];
    let mut declared = [false; MAX_KNOWN_IDS];
    let mut adjacency = [[false; MAX_KNOWN_IDS]; MAX_KNOWN_IDS];
    let mut known_count = 0;
    for index in 0..initial_count {
        let node = values[3 + index];
        if node < i32::MIN as i64 || node > i32::MAX as i64 || find_id(&ids, known_count, node).is_some() {
            return -1;
        }
        let Some(slot) = ensure_id(&mut ids, &mut declared, &mut known_count, node) else {
            return -1;
        };
        declared[slot] = true;
    }

    let mut result = [0_i64; MAX_OUTPUT_WORDS];
    let mut result_count = 0;
    let operations_offset = 3 + initial_count;
    for index in 0..operation_count {
        let offset = operations_offset + index * 3;
        let op = values[offset];
        let first = values[offset + 1];
        let second = values[offset + 2];
        if first < i32::MIN as i64 || first > i32::MAX as i64 || second < i32::MIN as i64 || second > i32::MAX as i64 {
            return -1;
        }
        match op {
            0 => {
                if second != 0 {
                    return -1;
                }
                if let Some(slot) = find_id(&ids, known_count, first) {
                    if declared[slot] {
                        return -1;
                    }
                }
                let Some(slot) = ensure_id(&mut ids, &mut declared, &mut known_count, first) else {
                    return -1;
                };
                declared[slot] = true;
            }
            1 => {
                let Some(from) = find_id(&ids, known_count, first) else {
                    return -1;
                };
                if !declared[from] {
                    return -1;
                }
                let mut to = find_id(&ids, known_count, second);
                if !directed {
                    match to {
                        Some(slot) if declared[slot] => {}
                        _ => return -1,
                    }
                }
                if to.is_none() {
                    to = ensure_id(&mut ids, &mut declared, &mut known_count, second);
                }
                let Some(to) = to else {
                    return -1;
                };
                if adjacency[from][to] {
                    return -1;
                }
                adjacency[from][to] = true;
                if !directed {
                    adjacency[to][from] = true;
                }
            }
            2 => {
                if second != 0 {
                    return -1;
                }
                let Some(node) = find_id(&ids, known_count, first) else {
                    return -1;
                };
                if !declared[node] {
                    return -1;
                }
                let mut sorted = [0_i64; MAX_KNOWN_IDS];
                let mut neighbor_count = 0;
                for neighbor in 0..known_count {
                    if adjacency[node][neighbor] {
                        sorted[neighbor_count] = ids[neighbor];
                        neighbor_count += 1;
                    }
                }
                sorted[..neighbor_count].sort_unstable();
                if result_count + 2 + neighbor_count > MAX_OUTPUT_WORDS {
                    return -1;
                }
                result[result_count] = first;
                result[result_count + 1] = neighbor_count as i64;
                result_count += 2;
                for neighbor in 0..neighbor_count {
                    result[result_count] = sorted[neighbor];
                    result_count += 1;
                }
            }
            _ => return -1,
        }
    }

    let output_bytes = result_count * 8;
    if output_bytes > MAX_OUTPUT_BYTES {
        return -1;
    }
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..result_count {
        write_i64_le(output_slice, index * 8, result[index]);
    }
    output_bytes as i64
}
