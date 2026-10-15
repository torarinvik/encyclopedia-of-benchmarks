const MAX_NODES: usize = 63;

unsafe fn count_from(input: *const i64, node: usize, sum: i64, target: i64) -> i64 {
    let base = 2 + 3 * node;
    let mut count = if sum == target { 1 } else { 0 };
    let left = *input.add(base + 1);
    let right = *input.add(base + 2);
    if left >= 0 { let child = left as usize; count += count_from(input, child, sum + *input.add(2 + 3 * child), target); }
    if right >= 0 { let child = right as usize; count += count_from(input, child, sum + *input.add(2 + 3 * child), target); }
    count
}

unsafe fn start_at_each_node(input: *const i64, node: usize) -> i64 {
    let base = 2 + 3 * node;
    let mut count = count_from(input, node, *input.add(base), *input);
    let left = *input.add(base + 1);
    let right = *input.add(base + 2);
    if left >= 0 { count += start_at_each_node(input, left as usize); }
    if right >= 0 { count += start_at_each_node(input, right as usize); }
    count
}

#[no_mangle]
pub unsafe extern "C" fn binary_tree_path_sum(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let count_value = *input.add(1);
    if count_value < 0 || count_value > MAX_NODES as i64 { return -1; }
    let count = count_value as usize;
    if length != 2 + 3 * count { return -1; }
    if count == 0 { return 0; }
    let mut parents = [0_usize; MAX_NODES];
    for node in 0..count {
        let base = 2 + 3 * node;
        let value = *input.add(base);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        for side in 1..=2 {
            let child = *input.add(base + side);
            if child < -1 || child >= count as i64 { return -1; }
            if child >= 0 {
                parents[child as usize] += 1;
                if parents[child as usize] > 1 { return -1; }
            }
        }
    }
    if parents[0] != 0 || (1..count).any(|node| parents[node] != 1) { return -1; }
    let mut seen = [false; MAX_NODES];
    let mut stack = [0_usize; MAX_NODES];
    let (mut top, mut reached) = (1_usize, 0_usize);
    stack[0] = 0;
    while top > 0 {
        top -= 1;
        let node = stack[top];
        if seen[node] { return -1; }
        seen[node] = true; reached += 1;
        let base = 2 + 3 * node;
        let left = *input.add(base + 1);
        let right = *input.add(base + 2);
        if left >= 0 { stack[top] = left as usize; top += 1; }
        if right >= 0 { stack[top] = right as usize; top += 1; }
    }
    if reached != count { return -1; }
    start_at_each_node(input, 0)
}
