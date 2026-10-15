const MAX_NODES: usize = 400;
const INVALID_RESULT: i64 = -9_000_000_000_000_000_000;

unsafe fn subtree_sum(nodes: *const i64, index: i64) -> i64 {
    if index < 0 { return 0; }
    let base = index as usize * 3;
    *nodes.add(base) + subtree_sum(nodes, *nodes.add(base + 1)) + subtree_sum(nodes, *nodes.add(base + 2))
}
unsafe fn check_node(nodes: *const i64, index: i64) -> bool {
    let base = index as usize * 3;
    let value = *nodes.add(base); let left = *nodes.add(base + 1); let right = *nodes.add(base + 2);
    if left == -1 && right == -1 { return true; }
    let left_sum = subtree_sum(nodes, left); let right_sum = subtree_sum(nodes, right);
    let left_ok = left == -1 || check_node(nodes, left);
    let right_ok = right == -1 || check_node(nodes, right);
    value == left_sum + right_sum && left_ok && right_ok
}

#[no_mangle]
pub unsafe extern "C" fn is_sum_tree(nodes: *const i64, count: usize, root: i64) -> i64 {
    if nodes.is_null() || count == 0 || count > MAX_NODES || root < 0 || root as u64 >= count as u64 { return INVALID_RESULT; }
    let mut seen = [false; MAX_NODES]; let mut stack = [0i64; MAX_NODES * 2]; let mut top = 0usize;
    stack[top] = root; top += 1;
    while top > 0 {
        top -= 1; let index = stack[top];
        if index < 0 || index as u64 >= count as u64 || seen[index as usize] { return INVALID_RESULT; }
        seen[index as usize] = true;
        let base = index as usize * 3;
        let value = *nodes.add(base); let left = *nodes.add(base + 1); let right = *nodes.add(base + 2);
        if !(-1_000_000_000..=1_000_000_000).contains(&value) || left < -1 || right < -1 ||
            (left >= 0 && left as u64 >= count as u64) || (right >= 0 && right as u64 >= count as u64) { return INVALID_RESULT; }
        if left >= 0 { stack[top] = left; top += 1; }
        if right >= 0 { stack[top] = right; top += 1; }
    }
    if check_node(nodes, root) { 1 } else { 0 }
}
