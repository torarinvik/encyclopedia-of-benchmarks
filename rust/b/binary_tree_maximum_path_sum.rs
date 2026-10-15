/// Carry the largest downward gain upward and update the best path at each node.
const MAX_NODE_COUNT: usize = 1023;
const ERROR_SENTINEL: i64 = -2_000_000_000;

unsafe fn maximum_gain(nodes: *const i64, node_count: usize, node: i64,
                       best_path: &mut i64) -> i64 {
    if node == -1 { return 0; }
    if node < 0 || node as u64 >= node_count as u64 { return ERROR_SENTINEL; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if !(-1000..=1000).contains(&value) || left < -1 ||
        (left >= 0 && left as u64 >= node_count as u64) || right < -1 ||
        (right >= 0 && right as u64 >= node_count as u64) { return ERROR_SENTINEL; }
    let left_gain = maximum_gain(nodes, node_count, left, best_path);
    if left_gain == ERROR_SENTINEL { return ERROR_SENTINEL; }
    let right_gain = maximum_gain(nodes, node_count, right, best_path);
    if right_gain == ERROR_SENTINEL { return ERROR_SENTINEL; }
    let positive_left = left_gain.max(0);
    let positive_right = right_gain.max(0);
    let through_node = value + positive_left + positive_right;
    *best_path = (*best_path).max(through_node);
    value + positive_left.max(positive_right)
}

#[no_mangle]
pub unsafe extern "C" fn binary_tree_maximum_path_sum(nodes: *const i64,
    node_count: usize, root_index: i64) -> i64 {
    if node_count == 0 || node_count > MAX_NODE_COUNT || nodes.is_null() ||
        root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    let mut best_path = -2_147_483_648_i64;
    let gain = maximum_gain(nodes, node_count, root_index, &mut best_path);
    if gain == ERROR_SENTINEL { return -1; }
    best_path
}
