const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_INPUT_LENGTH: usize = 131;
const MAX_NODES: usize = 193;
const INVALID_RESULT: i64 = i64::MIN;

#[no_mangle]
pub unsafe extern "C" fn persistent_segment_tree_range_kth(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if !(1..=MAX_N as i64).contains(&values[0]) || !(0..=MAX_Q as i64).contains(&values[1]) {
        return INVALID_RESULT;
    }
    let n = values[0] as usize;
    let q = values[1] as usize;
    if length != 2 + n + 3 * q { return INVALID_RESULT; }

    let mut coordinates = [0_i64; MAX_N];
    for i in 0..n {
        let value = values[2 + i];
        if !(-1000..=1000).contains(&value) { return INVALID_RESULT; }
        coordinates[i] = value;
    }
    for i in 1..n {
        let value = coordinates[i];
        let mut j = i;
        while j > 0 && coordinates[j - 1] > value {
            coordinates[j] = coordinates[j - 1];
            j -= 1;
        }
        coordinates[j] = value;
    }
    let mut distinct = 0;
    for i in 0..n {
        if distinct == 0 || coordinates[i] != coordinates[distinct - 1] {
            coordinates[distinct] = coordinates[i];
            distinct += 1;
        }
    }
    let query_offset = 2 + n;
    for qi in 0..q {
        let at = query_offset + 3 * qi;
        let left = values[at];
        let right = values[at + 1];
        let k = values[at + 2];
        if left < 0 || right < left || right >= n as i64 || k < 1 || k > right - left + 1 {
            return INVALID_RESULT;
        }
    }

    let mut left_child = [0_i32; MAX_NODES];
    let mut right_child = [0_i32; MAX_NODES];
    let mut counts = [0_i32; MAX_NODES];
    let mut roots = [0_i32; MAX_N + 1];
    let mut node_count = 1_usize;
    for i in 0..n {
        let value = values[2 + i];
        let mut low = 0;
        let mut high = distinct;
        while low < high {
            let middle = low + (high - low) / 2;
            if coordinates[middle] < value { low = middle + 1; } else { high = middle; }
        }
        let rank = low;
        let previous_root = roots[i] as usize;
        if node_count >= MAX_NODES { return INVALID_RESULT; }
        let new_root = node_count;
        node_count += 1;
        left_child[new_root] = left_child[previous_root];
        right_child[new_root] = right_child[previous_root];
        counts[new_root] = counts[previous_root] + 1;
        let mut old_node = previous_root;
        let mut new_node = new_root;
        low = 0;
        high = distinct;
        while high - low > 1 {
            let middle = low + (high - low) / 2;
            let old_child = (if rank < middle { left_child[old_node] } else { right_child[old_node] }) as usize;
            if node_count >= MAX_NODES { return INVALID_RESULT; }
            let new_child = node_count;
            node_count += 1;
            left_child[new_child] = left_child[old_child];
            right_child[new_child] = right_child[old_child];
            counts[new_child] = counts[old_child] + 1;
            if rank < middle {
                left_child[new_node] = new_child as i32;
                high = middle;
            } else {
                right_child[new_node] = new_child as i32;
                low = middle;
            }
            old_node = old_child;
            new_node = new_child;
        }
        roots[i + 1] = new_root as i32;
    }

    let mut checksum = 0_i64;
    for qi in 0..q {
        let at = query_offset + 3 * qi;
        let left = values[at] as usize;
        let right = values[at + 1] as usize;
        let mut k = values[at + 2] as i32;
        let mut before = roots[left] as usize;
        let mut after = roots[right + 1] as usize;
        let mut low = 0;
        let mut high = distinct;
        while high - low > 1 {
            let middle = low + (high - low) / 2;
            let in_left = left_child[after] as usize;
            let out_left = left_child[before] as usize;
            let left_count = counts[in_left] - counts[out_left];
            if k <= left_count {
                before = out_left;
                after = in_left;
                high = middle;
            } else {
                k -= left_count;
                before = right_child[before] as usize;
                after = right_child[after] as usize;
                low = middle;
            }
        }
        checksum += (qi as i64 + 1) * coordinates[low];
    }
    checksum
}
