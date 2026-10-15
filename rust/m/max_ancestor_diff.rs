/// Recursively carry the minimum and maximum ancestor values down each path.
const MAX_NODE_COUNT: usize = 1023;

unsafe fn visit(nodes: *const i64, node_count: usize, node: i64,
                path_min: i64, path_max: i64) -> i64 {
    if node == -1 { return 0; }
    if node < 0 || node as u64 >= node_count as u64 { return -1; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    if !(-100_000..=100_000).contains(&value) { return -1; }
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if left < -1 || (left >= 0 && left as u64 >= node_count as u64) ||
        right < -1 || (right >= 0 && right as u64 >= node_count as u64) { return -1; }
    let mut best = (path_min - value).abs().max((path_max - value).abs());
    let low = path_min.min(value);
    let high = path_max.max(value);
    let left_best = visit(nodes, node_count, left, low, high);
    if left_best < 0 { return -1; }
    let right_best = visit(nodes, node_count, right, low, high);
    if right_best < 0 { return -1; }
    best = best.max(left_best).max(right_best);
    best
}

#[no_mangle]
pub unsafe extern "C" fn max_ancestor_diff(nodes: *const i64, node_count: usize, root_index: i64) -> i64 {
    if node_count == 0 || node_count > MAX_NODE_COUNT || nodes.is_null() ||
        root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    let root_value = *nodes.add(3 * root_index as usize);
    if !(-100_000..=100_000).contains(&root_value) { return -1; }
    visit(nodes, node_count, root_index, root_value, root_value)
}
