/// Recursive inorder traversal that writes into caller-owned storage.
const MAX_NODE_COUNT: usize = 100;

unsafe fn inorder_visit(nodes: *const i64, node_count: usize, node: i64,
    output: *mut i64, capacity: usize, used: &mut usize) -> bool {
    if node == -1 { return true; }
    if node < 0 || node as u64 >= node_count as u64 { return false; }
    let index = node as usize;
    let value = *nodes.add(3 * index);
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if value < -100 || value > 100 || left < -1 || right < -1 ||
        (left >= 0 && left as u64 >= node_count as u64) ||
        (right >= 0 && right as u64 >= node_count as u64) { return false; }
    if !inorder_visit(nodes, node_count, left, output, capacity, used) { return false; }
    if *used >= capacity { return false; }
    *output.add(*used) = value;
    *used += 1;
    inorder_visit(nodes, node_count, right, output, capacity, used)
}

#[no_mangle]
pub unsafe extern "C" fn binary_tree_inorder_traversal(nodes: *const i64,
    node_count: usize, root_index: i64, output: *mut i64, output_capacity: usize) -> i64 {
    if node_count > MAX_NODE_COUNT || output_capacity < node_count { return -1; }
    if node_count == 0 { return if root_index == -1 { 0 } else { -1 }; }
    if nodes.is_null() || output.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 {
        return -1;
    }
    let mut used = 0usize;
    if !inorder_visit(nodes, node_count, root_index, output, output_capacity, &mut used) ||
        used != node_count { return -1; }
    used as i64
}
