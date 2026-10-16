const MAX_DIMENSION: usize = 8;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_INPUT_LENGTH: usize = 5 + MAX_CELLS;
const MAX_OUTPUT_VALUES: usize = 1 + MAX_CELLS;

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { output[offset + byte] = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn bidirectional_breadth_first_search(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let rows_value = values[0];
    let cols_value = values[1];
    if rows_value < 1 || rows_value > MAX_DIMENSION as i64 || cols_value < 1 || cols_value > MAX_DIMENSION as i64 { return -1; }
    let rows = rows_value as usize;
    let cols = cols_value as usize;
    let cells = rows * cols;
    let start_value = values[2];
    let goal_value = values[3];
    let blocked_count_value = values[4];
    if start_value < 0 || start_value >= cells as i64 || goal_value < 0 || goal_value >= cells as i64 || blocked_count_value < 0 || blocked_count_value > cells as i64 { return -1; }
    let blocked_count = blocked_count_value as usize;
    if length != 5 + blocked_count { return -1; }
    let start = start_value as usize;
    let goal = goal_value as usize;
    let mut blocked = [false; MAX_CELLS];
    for index in 0..blocked_count {
        let value = values[5 + index];
        if value < 0 || value >= cells as i64 { return -1; }
        let cell = value as usize;
        if blocked[cell] { return -1; }
        blocked[cell] = true;
    }
    if blocked[start] || blocked[goal] { return -1; }

    let mut distance = [-1i64; 2 * MAX_CELLS];
    let mut parent = [-1i64; 2 * MAX_CELLS];
    let mut queues = [0usize; 2 * MAX_CELLS];
    let mut head = [0usize; 2];
    let mut tail = [1usize; 2];
    distance[start] = 0;
    distance[MAX_CELLS + goal] = 0;
    queues[0] = start;
    queues[MAX_CELLS] = goal;
    let mut meeting = if start == goal { Some(start) } else { None };
    while meeting.is_none() && head[0] < tail[0] && head[1] < tail[1] {
        for side in 0..2 {
            if meeting.is_some() { break; }
            let layer_end = tail[side];
            while head[side] < layer_end {
                let node = queues[side * MAX_CELLS + head[side]];
                head[side] += 1;
            let row = node / cols;
            let col = node % cols;
            let mut neighbors = [usize::MAX; 4];
            if row > 0 { neighbors[0] = node - cols; }
            if col > 0 { neighbors[1] = node - 1; }
            if row + 1 < rows { neighbors[2] = node + cols; }
            if col + 1 < cols { neighbors[3] = node + 1; }
            for neighbor in neighbors {
                if neighbor == usize::MAX || blocked[neighbor] || distance[side * MAX_CELLS + neighbor] >= 0 { continue; }
                distance[side * MAX_CELLS + neighbor] = distance[side * MAX_CELLS + node] + 1;
                parent[side * MAX_CELLS + neighbor] = node as i64;
                    queues[side * MAX_CELLS + tail[side]] = neighbor;
                    tail[side] += 1;
                    if distance[(1 - side) * MAX_CELLS + neighbor] >= 0 {
                        meeting = Some(neighbor);
                        break;
                    }
                }
                if meeting.is_some() { break; }
            }
        }
    }
    let mut encoded = [0i64; MAX_OUTPUT_VALUES];
    let mut value_count = 1usize;
    if let Some(meeting_cell) = meeting {
        let mut reverse_path = [0usize; MAX_CELLS];
        let mut prefix_count = 0usize;
        let mut current = meeting_cell as i64;
        while current >= 0 {
            reverse_path[prefix_count] = current as usize;
            prefix_count += 1;
            if current as usize == start { break; }
            current = parent[current as usize];
        }
        let mut path_count = 0usize;
        for index in 0..prefix_count {
            encoded[1 + path_count] = reverse_path[prefix_count - 1 - index] as i64;
            path_count += 1;
        }
        current = parent[MAX_CELLS + meeting_cell];
        while current >= 0 {
            encoded[1 + path_count] = current;
            path_count += 1;
            current = parent[MAX_CELLS + current as usize];
        }
        encoded[0] = path_count as i64;
        value_count += path_count;
    } else {
        encoded[0] = 0;
    }
    let required = value_count * 8;
    if output.is_null() || capacity < required { return -2; }
    let out = unsafe { core::slice::from_raw_parts_mut(output, required) };
    for index in 0..value_count { put_i64(out, index * 8, encoded[index]); }
    required as i64
}
