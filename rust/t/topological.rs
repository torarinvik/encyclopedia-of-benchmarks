/// Source-faithful port of TheAlgorithms/Go graph.Topological.
#[no_mangle]
pub unsafe extern "C" fn topological(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > 66 || (length - 1) % 2 != 0 { return -2; }
    let values = std::slice::from_raw_parts(values, length);
    if !(0..=64).contains(&values[0]) { return -2; }
    let vertices = values[0] as usize;
    let edge_count = (length - 1) / 2;
    let mut dependencies = [0u8; 64];
    let mut adjacency = [0u64; 64];
    let mut answer = [0u8; 96];

    for edge in 0..edge_count {
        let origin_value = values[1 + 2 * edge];
        let destination_value = values[2 + 2 * edge];
        if origin_value < 0 || destination_value < 0 ||
            origin_value as u64 >= vertices as u64 || destination_value as u64 >= vertices as u64 {
            return -2;
        }
        let origin = origin_value as usize;
        let destination = destination_value as usize;
        dependencies[destination] += 1;
        adjacency[origin] |= 1u64 << destination;
    }

    let mut answer_count = 0usize;
    for root in 0..vertices {
        if dependencies[root] != 0 { continue; }
        let mut stack = [0usize; 64];
        let mut top = 0usize;
        stack[top] = root;
        top += 1;
        while top > 0 {
            top -= 1;
            let origin = stack[top];
            answer[answer_count] = origin as u8;
            answer_count += 1;
            for destination in 0..vertices {
                let edge_mask = 1u64 << destination;
                if adjacency[origin] & edge_mask != 0 {
                    let mut in_stack = false;
                    for index in 0..top {
                        if stack[index] == destination {
                            in_stack = true;
                            break;
                        }
                    }
                    if !in_stack {
                        stack[top] = destination;
                        top += 1;
                    }
                }
                adjacency[origin] &= !edge_mask;
                adjacency[destination] &= !(1u64 << origin);
            }
        }
    }

    if output_capacity < answer_count || (answer_count != 0 && output.is_null()) { return -2; }
    for index in 0..answer_count {
        *output.add(index) = answer[index];
    }
    answer_count as i64
}
