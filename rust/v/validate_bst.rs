/// Check strict BST bounds over a valid indexed binary tree.
const MAX_NODE_COUNT: usize = 1023;

unsafe fn validate_subtree(nodes: *const i64, node_count: usize, node: i64,
                           has_lower: bool, lower: i64, has_upper: bool, upper: i64) -> i64 {
    if node == -1 { return 1; }
    if node < 0 || node as u64 >= node_count as u64 { return -1; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if value < i32::MIN as i64 || value > i32::MAX as i64 ||
        left < -1 || (left >= 0 && left as u64 >= node_count as u64) ||
        right < -1 || (right >= 0 && right as u64 >= node_count as u64) { return -1; }
    if (has_lower && value <= lower) || (has_upper && value >= upper) { return 0; }
    let left_result = validate_subtree(nodes, node_count, left, has_lower, lower, true, value);
    if left_result <= 0 { return left_result; }
    validate_subtree(nodes, node_count, right, true, value, has_upper, upper)
}

#[no_mangle]
pub unsafe extern "C" fn validate_bst(nodes: *const i64, node_count: usize, root_index: i64) -> i64 {
    if node_count > MAX_NODE_COUNT { return -1; }
    if node_count == 0 { return if root_index == -1 { 1 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    validate_subtree(nodes, node_count, root_index, false, 0, false, 0)
}
