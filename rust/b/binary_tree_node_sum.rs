/// Sum every node reachable from the root of a bounded indexed binary tree.
const MAX_NODE_COUNT: usize = 900;
const INVALID_RESULT: i64 = -9_000_000_000_000_000_000;

unsafe fn sum_visit(nodes: *const i64, node_count: usize, node: i64, depth: usize) -> i64 {
    if node < 0 || node as u64 >= node_count as u64 || depth >= node_count { return INVALID_RESULT; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if !(-1_000_000_000..=1_000_000_000).contains(&value) || left < -1 || right < -1 ||
        (left >= 0 && left as u64 >= node_count as u64) ||
        (right >= 0 && right as u64 >= node_count as u64) { return INVALID_RESULT; }
    let left_sum = if left == -1 { 0 } else { sum_visit(nodes, node_count, left, depth + 1) };
    if left_sum == INVALID_RESULT { return INVALID_RESULT; }
    let right_sum = if right == -1 { 0 } else { sum_visit(nodes, node_count, right, depth + 1) };
    if right_sum == INVALID_RESULT { return INVALID_RESULT; }
    value + left_sum + right_sum
}

#[no_mangle]
pub unsafe extern "C" fn binary_tree_node_sum(nodes: *const i64, node_count: usize,
                                                root_index: i64) -> i64 {
    if nodes.is_null() || node_count == 0 || node_count > MAX_NODE_COUNT || root_index < 0 ||
        root_index as u64 >= node_count as u64 { return INVALID_RESULT; }
    sum_visit(nodes, node_count, root_index, 0)
}
