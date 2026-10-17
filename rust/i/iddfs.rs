const MAX_VERTICES: usize = 16;
const MAX_NEIGHBORS: usize = 64;
const MAX_DEPTH: usize = 8;
const MAX_VALID_INPUT_LENGTH: usize = 4 + 2 * MAX_VERTICES + MAX_NEIGHBORS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_VALID_INPUT_LENGTH + 1;
const MAX_PATH_LENGTH: usize = MAX_DEPTH + 1;
const MAX_OUTPUT_VALUES: usize = 3 + MAX_PATH_LENGTH;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn iddfs(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_start = input[0];
    let raw_target = input[1];
    let raw_depth = input[2];
    let raw_entries = input[3];
    if raw_start < 1 || raw_start > MAX_VERTICES as i64 ||
        raw_target < 1 || raw_target > MAX_VERTICES as i64 ||
        raw_depth < 0 || raw_depth > MAX_DEPTH as i64 ||
        raw_entries < 0 || raw_entries > MAX_VERTICES as i64 { return -1; }
    let start = raw_start as usize;
    let target = raw_target as usize;
    let depth_limit = raw_depth as usize;
    let entry_count = raw_entries as usize;

    let mut adjacency = [[0i32; MAX_NEIGHBORS]; MAX_VERTICES];
    let mut degree_count = [0usize; MAX_VERTICES];
    let mut named = [false; MAX_VERTICES];
    let mut max_vertex = 0usize;
    let mut total_neighbors = 0usize;
    let mut cursor = 4usize;
    for _ in 0..entry_count {
        if cursor + 2 > length { return -1; }
        let raw_vertex = input[cursor]; cursor += 1;
        let raw_degree = input[cursor]; cursor += 1;
        if raw_vertex < 1 || raw_vertex > MAX_VERTICES as i64 ||
            raw_degree < 0 || raw_degree > MAX_NEIGHBORS as i64 { return -1; }
        let vertex = raw_vertex as usize;
        let degree = raw_degree as usize;
        if named[vertex - 1] || degree > length - cursor || total_neighbors + degree > MAX_NEIGHBORS { return -1; }
        named[vertex - 1] = true;
        max_vertex = max_vertex.max(vertex);
        total_neighbors += degree;
        for _ in 0..degree {
            let raw_neighbor = input[cursor]; cursor += 1;
            if raw_neighbor < -(MAX_VERTICES as i64) || raw_neighbor > MAX_VERTICES as i64 { return -1; }
            if raw_neighbor > max_vertex as i64 { max_vertex = raw_neighbor as usize; }
            if raw_neighbor >= 1 {
                adjacency[vertex - 1][degree_count[vertex - 1]] = raw_neighbor as i32;
                degree_count[vertex - 1] += 1;
            }
        }
    }
    if cursor != length { return -1; }
    if max_vertex != 0 && (start > max_vertex || target > max_vertex) { return -1; }

    let mut path = [0i64; MAX_PATH_LENGTH];
    let mut next_neighbor = [0usize; MAX_PATH_LENGTH];
    let mut path_length = 0usize;
    let mut found_depth = 0usize;
    let mut found = false;
    if max_vertex != 0 {
        for limit in 0..=depth_limit {
            path_length = 1;
            path[0] = start as i64;
            next_neighbor[0] = 0;
            if start == target { found = true; found_depth = 0; break; }
            while path_length != 0 && !found {
                let frame = path_length - 1;
                let current = path[frame] as usize;
                if frame >= limit || next_neighbor[frame] >= degree_count[current - 1] {
                    path_length -= 1;
                    continue;
                }
                let neighbor = adjacency[current - 1][next_neighbor[frame]] as usize;
                next_neighbor[frame] += 1;
                if path[..path_length].contains(&(neighbor as i64)) { continue; }
                path[path_length] = neighbor as i64;
                path_length += 1;
                if neighbor == target { found = true; found_depth = path_length - 1; }
                else { next_neighbor[path_length - 1] = 0; }
            }
            if found { break; }
        }
    }

    let mut result = [0i64; MAX_OUTPUT_VALUES];
    let mut result_count = 3usize;
    result[0] = if found { 1 } else { 0 };
    result[1] = if found { found_depth as i64 } else { -1 };
    result[2] = if found { path_length as i64 } else { 0 };
    if found {
        result_count += path_length;
        result[3..result_count].copy_from_slice(&path[..path_length]);
    }
    let required = result_count * 8;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..result_count { store_i64_le(output, 8 * index, result[index]); }
    required as i64
}
