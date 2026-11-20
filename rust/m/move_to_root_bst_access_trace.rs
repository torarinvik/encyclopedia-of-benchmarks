#[no_mangle]
pub extern "C" fn move_to_root_bst_access_trace(values: *const i64, length: usize) -> i64 {
    const MAX_INITIAL: usize = 16;
    const MAX_ACCESSES: usize = 32;
    if values.is_null() || !(2..=51).contains(&length) {
        return -1;
    }
    // The caller provides the declared i64-array frame at this C ABI boundary.
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let initial_count = values[0];
    if !(0..=MAX_INITIAL as i64).contains(&initial_count) {
        return -1;
    }
    let query_count_index = 1 + initial_count as usize;
    if length < query_count_index + 1 {
        return -1;
    }
    let access_count = values[query_count_index];
    if !(0..=MAX_ACCESSES as i64).contains(&access_count)
        || length != query_count_index + 1 + access_count as usize
    {
        return -1;
    }

    let mut keys = [0_i64; MAX_INITIAL];
    let mut left = [-1_i32; MAX_INITIAL];
    let mut right = [-1_i32; MAX_INITIAL];
    let mut parent = [-1_i32; MAX_INITIAL];
    for index in 0..initial_count as usize {
        let key = values[1 + index];
        if !(-100..=100).contains(&key) || values[1..1 + index].contains(&key) {
            return -1;
        }
        keys[index] = key;
    }
    for query in 0..access_count as usize {
        if !(-100..=100).contains(&values[query_count_index + 1 + query]) {
            return -1;
        }
    }

    let mut root = -1_i32;
    for node in 0..initial_count as usize {
        if root == -1 {
            root = node as i32;
            continue;
        }
        let mut current = root as usize;
        loop {
            if keys[node] < keys[current] {
                if left[current] == -1 {
                    left[current] = node as i32;
                    parent[node] = current as i32;
                    break;
                }
                current = left[current] as usize;
            } else if right[current] == -1 {
                right[current] = node as i32;
                parent[node] = current as i32;
                break;
            } else {
                current = right[current] as usize;
            }
        }
    }

    let mut result = 0_i64;
    for query_number in 1..=access_count as usize {
        let key = values[query_count_index + query_number];
        let mut node = root;
        let mut comparisons = 0_i64;
        while node != -1 {
            comparisons += 1;
            if key == keys[node as usize] {
                break;
            }
            node = if key < keys[node as usize] { left[node as usize] } else { right[node as usize] };
        }
        while node != -1 && parent[node as usize] != -1 {
            let at = node as usize;
            let old_parent = parent[at];
            let parent_index = old_parent as usize;
            let grandparent = parent[parent_index];
            if left[parent_index] == node {
                let middle = right[at];
                right[at] = old_parent;
                left[parent_index] = middle;
                if middle != -1 {
                    parent[middle as usize] = old_parent;
                }
            } else {
                let middle = left[at];
                left[at] = old_parent;
                right[parent_index] = middle;
                if middle != -1 {
                    parent[middle as usize] = old_parent;
                }
            }
            parent[parent_index] = node;
            parent[at] = grandparent;
            if grandparent == -1 {
                root = node;
            } else if left[grandparent as usize] == old_parent {
                left[grandparent as usize] = node;
            } else {
                right[grandparent as usize] = node;
            }
        }
        result += query_number as i64 * comparisons;
    }
    result
}
