/// Recursively compare opposite child pairs in an indexed binary tree.
const MAX_NODE_COUNT: usize = 1023;

unsafe fn mirror(nodes: *const i64, node_count: usize, left: i64, right: i64) -> i64 {
    if left == -1 || right == -1 { return if left == right { 1 } else { 0 }; }
    if left < 0 || right < 0 || left as u64 >= node_count as u64 || right as u64 >= node_count as u64 {
        return -1;
    }
    let left_node = left as usize;
    let right_node = right as usize;
    if *nodes.add(3 * left_node) != *nodes.add(3 * right_node) { return 0; }
    let left_left = *nodes.add(3 * left_node + 1);
    let left_right = *nodes.add(3 * left_node + 2);
    let right_left = *nodes.add(3 * right_node + 1);
    let right_right = *nodes.add(3 * right_node + 2);
    if left_left < -1 || left_left as u64 >= node_count as u64 && left_left >= 0 ||
        left_right < -1 || left_right as u64 >= node_count as u64 && left_right >= 0 ||
        right_left < -1 || right_left as u64 >= node_count as u64 && right_left >= 0 ||
        right_right < -1 || right_right as u64 >= node_count as u64 && right_right >= 0 {
        return -1;
    }
    let outer = mirror(nodes, node_count, left_left, right_right);
    if outer != 1 { return outer; }
    mirror(nodes, node_count, left_right, right_left)
}

#[no_mangle]
pub unsafe extern "C" fn symmetric_tree(nodes: *const i64, node_count: usize, root_index: i64) -> i64 {
    if node_count > MAX_NODE_COUNT { return -1; }
    if node_count == 0 { return if root_index == -1 { 1 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    let root = root_index as usize;
    let left = *nodes.add(3 * root + 1);
    let right = *nodes.add(3 * root + 2);
    if left < -1 || (left >= 0 && left as u64 >= node_count as u64) ||
        right < -1 || (right >= 0 && right as u64 >= node_count as u64) { return -1; }
    mirror(nodes, node_count, left, right)
}
