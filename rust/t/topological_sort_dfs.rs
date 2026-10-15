/// Deterministic depth-first topological sort with three-color cycle detection.
#[no_mangle]
pub extern "C" fn topological_sort_dfs(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > 66 || (length - 1) % 2 != 0 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 40 { return -2; }
    let vertices = values[0] as usize;
    let edge_count = (length - 1) / 2;
    let mut adjacency = [0u64; 40];
    let mut state = [0u8; 40];
    let mut stack = [0usize; 40];
    let mut next_neighbor = [0usize; 40];
    let mut order = [0usize; 40];

    for edge in 0..edge_count {
        let origin_value = values[1 + 2 * edge];
        let destination_value = values[2 + 2 * edge];
        if origin_value < 0 || destination_value < 0 ||
            origin_value as u64 >= vertices as u64 || destination_value as u64 >= vertices as u64 {
            return -2;
        }
        let origin = origin_value as usize;
        let destination = destination_value as usize;
        adjacency[origin] |= 1u64 << destination;
    }

    let mut count = 0usize;
    for root in 0..vertices {
        if state[root] != 0 { continue; }
        let mut top = 0usize;
        stack[top] = root;
        next_neighbor[top] = 0;
        state[root] = 1;
        loop {
            let origin = stack[top];
            let mut destination = next_neighbor[top];
            while destination < vertices && adjacency[origin] & (1u64 << destination) == 0 {
                destination += 1;
            }
            if destination == vertices {
                state[origin] = 2;
                order[count] = origin;
                count += 1;
                if top == 0 { break; }
                top -= 1;
                continue;
            }
            next_neighbor[top] = destination + 1;
            if state[destination] == 1 { return -1; }
            if state[destination] == 0 {
                top += 1;
                stack[top] = destination;
                next_neighbor[top] = 0;
                state[destination] = 1;
            }
        }
    }

    if output_capacity < vertices || (vertices != 0 && output.is_null()) { return -2; }
    for index in 0..count {
        unsafe { *output.add(index) = order[count - 1 - index] as u8; }
    }
    count as i64
}
