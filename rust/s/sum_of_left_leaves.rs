/// Sum leaf values reached through left-child links.
const MAX_NODE_COUNT: usize = 1023;
const ERROR_SENTINEL: i64 = -2_000_000_000;

unsafe fn visit(nodes: *const i64, node_count: usize, node: i64, is_left: bool) -> i64 {
    if node == -1 { return 0; }
    if node < 0 || node as u64 >= node_count as u64 { return ERROR_SENTINEL; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if !(-1000..=1000).contains(&value) || left < -1 ||
        (left >= 0 && left as u64 >= node_count as u64) || right < -1 ||
        (right >= 0 && right as u64 >= node_count as u64) { return ERROR_SENTINEL; }
    if left == -1 && right == -1 { return if is_left { value } else { 0 }; }
    let left_sum = visit(nodes, node_count, left, true);
    if left_sum == ERROR_SENTINEL { return ERROR_SENTINEL; }
    let right_sum = visit(nodes, node_count, right, false);
    if right_sum == ERROR_SENTINEL { return ERROR_SENTINEL; }
    left_sum + right_sum
}

#[no_mangle]
pub unsafe extern "C" fn sum_of_left_leaves(nodes: *const i64, node_count: usize,
                                             root_index: i64) -> i64 {
    if node_count > MAX_NODE_COUNT { return -1; }
    if node_count == 0 { return if root_index == -1 { 0 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    let result = visit(nodes, node_count, root_index, false);
    if result == ERROR_SENTINEL { -1 } else { result }
}
