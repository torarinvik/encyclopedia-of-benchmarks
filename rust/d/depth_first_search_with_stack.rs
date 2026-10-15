/// Stack-based DFS that marks vertices when they are pushed, matching the source order.
#[no_mangle]
pub extern "C" fn depth_first_search_with_stack(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > 66 || (length - 2) % 2 != 0 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 64 { return -2; }
    let vertices = values[0] as usize;
    let start_value = values[1];
    if vertices == 0 { return if start_value == -1 && length == 2 { 0 } else { -2 }; }
    if start_value < 0 || start_value as u64 >= vertices as u64 { return -2; }

    let mut adjacency = [0usize; 64 * 32];
    let mut degree = [0usize; 64];
    let mut state = [0u8; 64];
    let edge_count = (length - 2) / 2;
    for edge in 0..edge_count {
        let origin_value = values[2 + 2 * edge];
        let destination_value = values[3 + 2 * edge];
        if origin_value < 0 || destination_value < 0 ||
            origin_value as u64 >= vertices as u64 || destination_value as u64 >= vertices as u64 {
            return -2;
        }
        let origin = origin_value as usize;
        adjacency[origin * 32 + degree[origin]] = destination_value as usize;
        degree[origin] += 1;
    }

    let mut stack = [0usize; 33];
    let mut order = [0usize; 64];
    let mut stack_length = 1usize;
    let mut count = 0usize;
    let start = start_value as usize;
    state[start] = 1;
    stack[0] = start;
    while stack_length != 0 {
        stack_length -= 1;
        let vertex = stack[stack_length];
        if state[vertex] != 1 { continue; }
        order[count] = vertex;
        count += 1;
        for edge in 0..degree[vertex] {
            let neighbor = adjacency[vertex * 32 + edge];
            stack[stack_length] = neighbor;
            stack_length += 1;
            if state[neighbor] != 2 { state[neighbor] = 1; }
        }
        state[vertex] = 2;
    }
    if output_capacity < count || (count != 0 && output.is_null()) { return -2; }
    for index in 0..count {
        unsafe { *output.add(index) = order[index] as u8; }
    }
    count as i64
}
