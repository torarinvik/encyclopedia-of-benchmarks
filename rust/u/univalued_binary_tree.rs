/// Recursively check each node against its parent value.
const MAX_NODE_COUNT: usize = 1023;

unsafe fn is_univalued(nodes: *const i64, node_count: usize, node: i64) -> i64 {
    if node == -1 { return 1; }
    if node < 0 || node as u64 >= node_count as u64 { return -1; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if left < -1 || (left >= 0 && left as u64 >= node_count as u64) ||
        right < -1 || (right >= 0 && right as u64 >= node_count as u64) { return -1; }
    if (left >= 0 && *nodes.add(3 * left as usize) != value) ||
        (right >= 0 && *nodes.add(3 * right as usize) != value) { return 0; }
    let left_result = is_univalued(nodes, node_count, left);
    if left_result <= 0 { return left_result; }
    is_univalued(nodes, node_count, right)
}

#[no_mangle]
pub unsafe extern "C" fn univalued_binary_tree(nodes: *const i64, node_count: usize,
                                                root_index: i64) -> i64 {
    if node_count > MAX_NODE_COUNT { return -1; }
    if node_count == 0 { return if root_index == -1 { 1 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    is_univalued(nodes, node_count, root_index)
}
