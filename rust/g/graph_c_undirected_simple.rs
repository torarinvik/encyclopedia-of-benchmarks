const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 2047;

unsafe fn put_i64(output: *mut u8, slot: usize, value: i64) {
    for (byte, value_byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(slot * 8 + byte) = *value_byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn graph_c_undirected_simple(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_VERTICES as i64 || values[1] < 0 || values[1] > MAX_EDGES as i64 { return -1; }
    let vertices = values[0] as usize;
    let edge_count = values[1] as usize;
    if length != 2 + 2 * edge_count { return -1; }

    let mut adjacency = [[0i64; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..edge_count {
        let (left_value, right_value) = (values[2 + 2 * edge], values[3 + 2 * edge]);
        if left_value < 0 || right_value < 0 || left_value as usize >= vertices || right_value as usize >= vertices { return -1; }
        let (left, right) = (left_value as usize, right_value as usize);
        adjacency[left][right] = 1;
        adjacency[right][left] = 1;
    }
    let count = vertices * vertices;
    if output.is_null() || capacity < count * 8 { return -2; }
    for row in 0..vertices {
        for column in 0..vertices {
            unsafe { put_i64(output, row * vertices + column, adjacency[row][column]); }
        }
    }
    (count * 8) as i64
}
