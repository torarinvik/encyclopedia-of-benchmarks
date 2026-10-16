/// Return vertices with no outgoing neighbors, in ascending vertex order.
#[no_mangle]
pub extern "C" fn find_isolated_nodes(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 65 || (length - 1) % 2 != 0 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 64 { return -2; }
    let vertices = values[0] as usize;
    let mut adjacency = [0u64; 64];
    let edge_count = (length - 1) / 2;
    for edge in 0..edge_count {
        let origin_value = values[1 + 2 * edge];
        let destination_value = values[2 + 2 * edge];
        if origin_value < 0 || destination_value < 0 ||
            origin_value as u64 >= vertices as u64 || destination_value as u64 >= vertices as u64 {
            return -2;
        }
        adjacency[origin_value as usize] |= 1u64 << destination_value as u32;
    }
    let mut isolated = [0u8; 64];
    let mut count = 0usize;
    for vertex in 0..vertices {
        if adjacency[vertex] == 0 {
            isolated[count] = vertex as u8;
            count += 1;
        }
    }
    if output_capacity < count || (count != 0 && output.is_null()) { return -2; }
    for index in 0..count {
        unsafe { *output.add(index) = isolated[index]; }
    }
    count as i64
}
