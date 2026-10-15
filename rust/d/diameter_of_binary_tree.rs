/// Count the path through the selected node, matching Node.diameter().
const MAX_NODE_COUNT: usize = 1023;
const ERROR_SENTINEL: i64 = -2_000_000_000;

unsafe fn height_and_check(nodes: *const i64, count: usize, node: i64,
    seen: &mut [bool; MAX_NODE_COUNT], visited: &mut usize) -> i64 {
    if node == -1 { return 0; }
    if node < 0 || node as u64 >= count as u64 { return ERROR_SENTINEL; }
    let index = node as usize;
    if seen[index] { return ERROR_SENTINEL; }
    seen[index] = true;
    *visited += 1;
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    if left < -1 || right < -1 ||
        (left >= 0 && left as u64 >= count as u64) ||
        (right >= 0 && right as u64 >= count as u64) { return ERROR_SENTINEL; }
    let left_height = height_and_check(nodes, count, left, seen, visited);
    if left_height == ERROR_SENTINEL { return ERROR_SENTINEL; }
    let right_height = height_and_check(nodes, count, right, seen, visited);
    if right_height == ERROR_SENTINEL { return ERROR_SENTINEL; }
    1 + left_height.max(right_height)
}

#[no_mangle]
pub unsafe extern "C" fn diameter_of_binary_tree(nodes: *const i64,
    node_count: usize, root_index: i64) -> i64 {
    if nodes.is_null() || node_count == 0 || node_count > MAX_NODE_COUNT ||
        root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    let root = root_index as usize;
    let left = *nodes.add(3 * root + 1);
    let right = *nodes.add(3 * root + 2);
    if left < -1 || right < -1 ||
        (left >= 0 && left as u64 >= node_count as u64) ||
        (right >= 0 && right as u64 >= node_count as u64) { return -1; }
    let mut seen = [false; MAX_NODE_COUNT];
    seen[root] = true;
    let mut visited = 1usize;
    let left_height = height_and_check(nodes, node_count, left, &mut seen, &mut visited);
    if left_height == ERROR_SENTINEL { return -1; }
    let right_height = height_and_check(nodes, node_count, right, &mut seen, &mut visited);
    if right_height == ERROR_SENTINEL || visited != node_count { return -1; }
    left_height + right_height + 1
}
