const MAX_NODES: usize = 64;
const MAX_EDGES: usize = 94;
const MAX_INPUT_LENGTH: usize = 4 + MAX_NODES + 2 * MAX_EDGES;
const MAX_OUTPUT_BYTES: usize = 128;

#[no_mangle]
pub unsafe extern "C" fn depth_first_search_target_route(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return -2; }
    let values = std::slice::from_raw_parts(values, length);
    if !(1..=MAX_NODES as i64).contains(&values[0])
        || !(0..=255).contains(&values[1])
        || !(0..=255).contains(&values[2]) { return -2; }
    let node_count = values[0] as usize;
    let start_label = values[1];
    let target_label = values[2];
    let edge_count_position = 3 + node_count;
    if edge_count_position >= length { return -2; }

    let labels = &values[3..edge_count_position];
    if labels.len() != node_count
        || labels.iter().any(|&label| !(0..=255).contains(&label))
        || labels.iter().enumerate().any(|(i, label)| labels[..i].contains(label)) { return -2; }
    let Some(start_index) = labels.iter().position(|&label| label == start_label) else { return -2; };

    let edge_count_value = values[edge_count_position];
    if !(0..=MAX_EDGES as i64).contains(&edge_count_value) { return -2; }
    let edge_count = edge_count_value as usize;
    if length != edge_count_position + 1 + 2 * edge_count { return -2; }

    let mut adjacency = [0u64; MAX_NODES];
    for edge in 0..edge_count {
        let left_label = values[edge_count_position + 1 + 2 * edge];
        let right_label = values[edge_count_position + 2 + 2 * edge];
        let Some(left) = labels.iter().position(|&label| label == left_label) else { return -2; };
        let Some(right) = labels.iter().position(|&label| label == right_label) else { return -2; };
        adjacency[left] |= 1u64 << right;
        adjacency[right] |= 1u64 << left;
    }

    let mut stack = [0usize; MAX_NODES];
    let mut stack_length = 1usize;
    stack[0] = start_index;
    let mut route = [0u8; MAX_OUTPUT_BYTES];
    let mut route_length = 0usize;
    while stack_length != 0 {
        stack_length -= 1;
        let current = stack[stack_length];
        if route_length == MAX_OUTPUT_BYTES { return -2; }
        route[route_length] = labels[current] as u8;
        route_length += 1;
        for neighbor in 0..node_count {
            let bit = 1u64 << neighbor;
            if adjacency[current] & bit != 0 && !stack[..stack_length].contains(&neighbor) {
                stack[stack_length] = neighbor;
                stack_length += 1;
            }
            adjacency[current] &= !bit;
            adjacency[neighbor] &= !(1u64 << current);
        }
        if labels[current] == target_label {
            if output_capacity < route_length || (route_length != 0 && output.is_null()) { return -2; }
            for index in 0..route_length { *output.add(index) = route[index]; }
            return route_length as i64;
        }
    }
    0
}
