/// Eagerly materialize a BST's in-order sequence, then consume it through an iterator.
const MAX_NODE_COUNT: usize = 1023;

#[no_mangle]
pub unsafe extern "C" fn bst_iterator(nodes: *const i64, node_count: usize, root_index: i64) -> i64 {
    if node_count > MAX_NODE_COUNT { return -1; }
    if node_count == 0 { return if root_index == -1 { 0 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    let mut iterator_values = [0_i64; MAX_NODE_COUNT];
    let mut stack = [0_usize; MAX_NODE_COUNT];
    let mut top = 0_usize;
    let mut value_count = 0_usize;
    let mut current = root_index;
    while current != -1 || top != 0 {
        while current != -1 {
            if current < 0 || current as u64 >= node_count as u64 || top >= node_count { return -1; }
            let index = current as usize;
            let left = *nodes.add(3 * index + 1);
            let right = *nodes.add(3 * index + 2);
            if left < -1 || (left >= 0 && left as u64 >= node_count as u64) ||
                right < -1 || (right >= 0 && right as u64 >= node_count as u64) { return -1; }
            stack[top] = index;
            top += 1;
            current = left;
        }
        top -= 1;
        let index = stack[top];
        if value_count >= node_count { return -1; }
        let value = *nodes.add(3 * index);
        if !(-100_000..=100_000).contains(&value) ||
            (value_count != 0 && iterator_values[value_count - 1] >= value) { return -1; }
        iterator_values[value_count] = value;
        value_count += 1;
        current = *nodes.add(3 * index + 2);
    }
    if value_count != node_count { return -1; }
    let mut checksum = 0_i64;
    let mut next_index = 0_usize;
    while next_index < value_count {
        checksum += (next_index as i64 + 1) * (iterator_values[next_index] + 100_001);
        next_index += 1;
    }
    checksum
}
