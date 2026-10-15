/// Preserve the source's full tree traversal while validating the BST input.
const MAX_NODE_COUNT: usize = 1023;
const MAX_VALUE: i64 = 100_000;

#[no_mangle]
pub unsafe extern "C" fn range_sum_bst(nodes: *const i64, node_count: usize,
    root_index: i64, low: i64, high: i64) -> i64 {
    if node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high { return -1; }
    if node_count == 0 { return if root_index == -1 { 0 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }

    let mut parents = [0i64; MAX_NODE_COUNT];
    let mut seen = [false; MAX_NODE_COUNT];
    let mut stack_node = [0i64; MAX_NODE_COUNT];
    let mut stack_low = [0i64; MAX_NODE_COUNT];
    let mut stack_high = [0i64; MAX_NODE_COUNT];
    for index in 0..node_count {
        let value = *nodes.add(3 * index);
        let left = *nodes.add(3 * index + 1);
        let right = *nodes.add(3 * index + 2);
        if value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && left as u64 >= node_count as u64) ||
            (right >= 0 && right as u64 >= node_count as u64) { return -1; }
        if left >= 0 {
            parents[left as usize] += 1;
            if parents[left as usize] > 1 { return -1; }
        }
        if right >= 0 {
            parents[right as usize] += 1;
            if parents[right as usize] > 1 { return -1; }
        }
    }
    let root = root_index as usize;
    if parents[root] != 0 { return -1; }
    for index in 0..node_count {
        if index != root && parents[index] != 1 { return -1; }
    }

    let mut top = 1usize;
    let mut visited = 0usize;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = MAX_VALUE + 1;
    let mut total = 0i64;
    while top > 0 {
        top -= 1;
        let index = stack_node[top] as usize;
        let lower = stack_low[top];
        let upper = stack_high[top];
        if seen[index] { return -1; }
        seen[index] = true;
        visited += 1;
        let value = *nodes.add(3 * index);
        let left = *nodes.add(3 * index + 1);
        let right = *nodes.add(3 * index + 2);
        if value <= lower || value >= upper { return -1; }
        if low <= value && value <= high { total += value; }
        if right >= 0 {
            stack_node[top] = right;
            stack_low[top] = value;
            stack_high[top] = upper;
            top += 1;
        }
        if left >= 0 {
            stack_node[top] = left;
            stack_low[top] = lower;
            stack_high[top] = value;
            top += 1;
        }
    }
    if visited != node_count { return -1; }
    total
}
