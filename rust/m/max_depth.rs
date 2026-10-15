/// Recursively return one plus the larger child depth for an indexed tree.
const MAX_NODE_COUNT: usize = 1023;

unsafe fn tree_depth(nodes: *const i64, node_count: usize, node: i64) -> i64 {
    if node == -1 { return 0; }
    if node < 0 || node as u64 >= node_count as u64 { return -1; }
    let index = node as usize;
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if left < -1 || (left >= 0 && left as u64 >= node_count as u64) ||
        right < -1 || (right >= 0 && right as u64 >= node_count as u64) { return -1; }
    let left_depth = tree_depth(nodes, node_count, left);
    if left_depth < 0 { return -1; }
    let right_depth = tree_depth(nodes, node_count, right);
    if right_depth < 0 { return -1; }
    1 + left_depth.max(right_depth)
}

#[no_mangle]
pub unsafe extern "C" fn max_depth(nodes: *const i64, node_count: usize, root_index: i64) -> i64 {
    if node_count > MAX_NODE_COUNT { return -1; }
    if node_count == 0 { return if root_index == -1 { 0 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    tree_depth(nodes, node_count, root_index)
}
