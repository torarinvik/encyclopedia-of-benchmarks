/// Directed cycle detection with iterative depth-first search and three colors.
#[no_mangle]
pub unsafe extern "C" fn cycle_check_directed_graph(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > 65 || (length - 1) % 2 != 0 { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if !(0..=64).contains(&values[0]) { return -1; }
    let vertices = values[0] as usize;
    let edge_count = (length - 1) / 2;
    if edge_count > 32 { return -1; }
    let mut adjacency = [0u64; 64];
    let mut state = [0u8; 64];
    let mut stack = [0usize; 64];
    let mut next_neighbor = [0usize; 64];
    for edge in 0..edge_count {
        let source = values[1 + 2 * edge];
        let destination = values[2 + 2 * edge];
        if source < 0 || destination < 0 || source as u64 >= vertices as u64 ||
            destination as u64 >= vertices as u64 { return -1; }
        adjacency[source as usize] |= 1u64 << destination as u32;
    }
    for root in 0..vertices {
        if state[root] != 0 { continue; }
        let mut top = 0usize;
        stack[0] = root;
        next_neighbor[0] = 0;
        state[root] = 1;
        loop {
            let node = stack[top];
            let mut destination = next_neighbor[top];
            while destination < vertices && adjacency[node] & (1u64 << destination) == 0 {
                destination += 1;
            }
            if destination == vertices {
                state[node] = 2;
                if top == 0 { break; }
                top -= 1;
                continue;
            }
            next_neighbor[top] = destination + 1;
            if state[destination] == 1 { return 1; }
            if state[destination] == 0 {
                top += 1;
                stack[top] = destination;
                next_neighbor[top] = 0;
                state[destination] = 1;
            }
        }
    }
    0
}
