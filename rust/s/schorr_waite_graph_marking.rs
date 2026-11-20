#[no_mangle]
pub unsafe extern "C" fn schorr_waite_graph_marking(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 66 { return -1; }

    let node_count_value = *input;
    let root = *input.add(1);
    if !(1..=32).contains(&node_count_value) { return -1; }
    let node_count = node_count_value as usize;
    if length != 2 + 2 * node_count || root < 0 || root >= node_count_value { return -1; }

    let mut left = [0_i64; 32];
    let mut right = [0_i64; 32];
    let mut marked = [false; 32];
    let mut phase = [false; 32];
    for node in 0..node_count {
        let left_child = *input.add(2 + 2 * node);
        let right_child = *input.add(3 + 2 * node);
        if left_child < -1 || left_child >= node_count_value
            || right_child < -1 || right_child >= node_count_value {
            return -1;
        }
        left[node] = left_child;
        right[node] = right_child;
    }

    let mut parent = -1_i64;
    let mut current = root;
    let mut temporary: i64;
    while parent != -1 || (current != -1 && !marked[current as usize]) {
        if current == -1 || marked[current as usize] {
            let frame = parent as usize;
            if phase[frame] {
                temporary = current;
                current = parent;
                parent = right[frame];
                right[frame] = temporary;
            } else {
                temporary = current;
                current = right[frame];
                right[frame] = left[frame];
                left[frame] = temporary;
                phase[frame] = true;
            }
        } else {
            temporary = parent;
            parent = current;
            current = left[parent as usize];
            left[parent as usize] = temporary;
            marked[parent as usize] = true;
            phase[parent as usize] = false;
        }
    }

    let mut reachable = 0_i64;
    for node in 0..node_count {
        if marked[node] { reachable |= 1_i64 << node; }
    }
    reachable
}
