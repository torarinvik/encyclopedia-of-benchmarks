/// Traverse a directed graph from start with fixed-size adjacency bitsets.
#[no_mangle]
pub extern "C" fn depth_first_search(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > 66 || (length - 2) % 2 != 0 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 64 { return -2; }
    let vertices = values[0] as usize;
    let start_value = values[1];
    if vertices == 0 { return if start_value == -1 && length == 2 { 0 } else { -2 }; }
    if start_value < 0 || start_value as u64 >= vertices as u64 { return -2; }
    let mut adjacency = [0u64; 64];
    let mut visited = [false; 64];
    let mut order = [0usize; 64];
    let edge_count = (length - 2) / 2;
    for edge in 0..edge_count {
        let origin_value = values[2 + 2 * edge];
        let destination_value = values[3 + 2 * edge];
        if origin_value < 0 || destination_value < 0 ||
            origin_value as u64 >= vertices as u64 || destination_value as u64 >= vertices as u64 {
            return -2;
        }
        let origin = origin_value as usize;
        let destination = destination_value as usize;
        adjacency[origin] |= 1u64 << destination;
    }
    let start = start_value as usize;
    let mut count = 0usize;
    visited[start] = true;
    let mut stack_vertex = [0usize; 64];
    let mut stack_next = [0usize; 64];
    let mut depth = 1usize;
    stack_vertex[0] = start;
    order[count] = start;
    count += 1;
    while depth != 0 {
        let frame = depth - 1;
        let origin = stack_vertex[frame];
        if stack_next[frame] == vertices {
            depth -= 1;
        } else {
            let destination = stack_next[frame];
            stack_next[frame] += 1;
            if adjacency[origin] & (1u64 << destination) != 0 && !visited[destination] {
                visited[destination] = true;
                order[count] = destination;
                count += 1;
                stack_vertex[depth] = destination;
                stack_next[depth] = 0;
                depth += 1;
            }
        }
    }
    if output_capacity < count || (count != 0 && output.is_null()) { return -2; }
    for index in 0..count {
        unsafe { *output.add(index) = order[index] as u8; }
    }
    count as i64
}
