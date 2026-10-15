const MAX_VERTICES: usize = 40;
const MAX_EDGES: usize = 780;

unsafe fn put_i64(output: *mut u8, slot: usize, value: i64) {
    for (byte, value_byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(slot * 8 + byte) = *value_byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn bfs_connected_undirected_visit_order(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_VERTICES as i64 || values[1] < 0 ||
        values[1] > MAX_EDGES as i64 || values[2] != 0 { return -1; }
    let vertices = values[0] as usize;
    let edge_count = values[1] as usize;
    if length != 3 + 2 * edge_count { return -1; }

    let mut adjacency = [0u64; MAX_VERTICES];
    for edge in 0..edge_count {
        let (left_value, right_value) = (values[3 + 2 * edge], values[4 + 2 * edge]);
        if left_value < 0 || right_value < 0 || left_value as usize >= vertices || right_value as usize >= vertices { return -1; }
        let (left, right) = (left_value as usize, right_value as usize);
        adjacency[left] |= 1u64 << right;
        adjacency[right] |= 1u64 << left;
    }
    let mut visited = [false; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let mut order = [0usize; MAX_VERTICES];
    let (mut head, mut tail, mut count) = (0usize, 0usize, 0usize);
    visited[0] = true;
    queue[tail] = 0;
    tail += 1;
    while head < tail {
        let vertex = queue[head];
        head += 1;
        order[count] = vertex;
        count += 1;
        for neighbor in 0..vertices {
            if adjacency[vertex] & (1u64 << neighbor) != 0 && !visited[neighbor] {
                visited[neighbor] = true;
                queue[tail] = neighbor;
                tail += 1;
            }
        }
    }
    if count != vertices { return -1; }
    if output.is_null() || capacity < vertices * 8 { return -2; }
    for index in 0..count {
        unsafe { put_i64(output, index, order[index] as i64); }
    }
    count as i64
}
