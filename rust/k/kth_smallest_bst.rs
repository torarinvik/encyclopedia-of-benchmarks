/// Inorder DFS decrements k and stops as soon as the requested node is found.
const MAX_NODE_COUNT: usize = 1023;
const MAX_VALUE: i64 = 10_000;
const INVALID_TREE_RESULT: i64 = i64::MIN;

unsafe fn kth_visit(nodes: *const i64, node_count: usize,
    node: i64, remaining: &mut i64) -> i64 {
    if node == -1 { return -1; }
    if node < 0 || node as u64 >= node_count as u64 { return INVALID_TREE_RESULT; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if value < 0 || value > MAX_VALUE || left < -1 || right < -1 ||
        (left >= 0 && left as u64 >= node_count as u64) ||
        (right >= 0 && right as u64 >= node_count as u64) { return INVALID_TREE_RESULT; }
    let left_result = kth_visit(nodes, node_count, left, remaining);
    if left_result >= 0 || left_result == INVALID_TREE_RESULT { return left_result; }
    *remaining -= 1;
    if *remaining == 0 { return value; }
    kth_visit(nodes, node_count, right, remaining)
}

#[no_mangle]
pub unsafe extern "C" fn kth_smallest_bst(nodes: *const i64, node_count: usize,
    root_index: i64, k: i64) -> i64 {
    if node_count == 0 || node_count > MAX_NODE_COUNT || nodes.is_null() ||
        root_index < 0 || root_index as u64 >= node_count as u64 || k < 1 || k as u64 > node_count as u64 {
        return -1;
    }
    let mut remaining = k;
    let result = kth_visit(nodes, node_count, root_index, &mut remaining);
    if result < 0 { return -1; }
    result
}
