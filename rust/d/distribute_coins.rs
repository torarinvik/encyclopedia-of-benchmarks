const MAX_NODE_COUNT: usize = 100;

fn absolute_i64(value: i64) -> i64 {
    if value < 0 { -value } else { value }
}

unsafe fn analyze(nodes: *const i64, node: i64, moves: &mut i64) -> i64 {
    if node == -1 { return 1; }
    let index = node as usize;
    let left = *nodes.add(3 * index + 1);
    let right = *nodes.add(3 * index + 2);
    let left_excess = analyze(nodes, left, moves);
    let right_excess = analyze(nodes, right, moves);
    *moves += absolute_i64(1 - left_excess) + absolute_i64(1 - right_excess);
    *nodes.add(3 * index) + left_excess + right_excess - 2
}

#[no_mangle]
pub unsafe extern "C" fn distribute_coins(nodes: *const i64, node_count: usize,
                                             root_index: i64) -> i64 {
    if node_count > MAX_NODE_COUNT { return -1; }
    if node_count == 0 { return if root_index == -1 { 0 } else { -1 }; }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }

    let mut parent = [-1i64; MAX_NODE_COUNT];
    let mut stack = [0usize; MAX_NODE_COUNT];
    let mut seen = [false; MAX_NODE_COUNT];
    let mut coin_total = 0i64;
    for node in 0..node_count {
        let value = *nodes.add(3 * node);
        if !(0..=100).contains(&value) { return -1; }
        coin_total += value;
        for edge in 1..=2 {
            let child = *nodes.add(3 * node + edge);
            if child < -1 || (child >= 0 && child as u64 >= node_count as u64) { return -1; }
            if child >= 0 {
                let child_index = child as usize;
                if parent[child_index] != -1 { return -1; }
                parent[child_index] = node as i64;
            }
        }
    }
    if coin_total != node_count as i64 { return -1; }
    let root = root_index as usize;
    if parent[root] != -1 { return -1; }
    for node in 0..node_count {
        if node != root && parent[node] == -1 { return -1; }
    }

    let mut top = 0usize;
    let mut reached = 0usize;
    stack[top] = root;
    top += 1;
    while top > 0 {
        top -= 1;
        let node = stack[top];
        if seen[node] { return -1; }
        seen[node] = true;
        reached += 1;
        for edge in 1..=2 {
            let child = *nodes.add(3 * node + edge);
            if child >= 0 {
                stack[top] = child as usize;
                top += 1;
            }
        }
    }
    if reached != node_count { return -1; }

    let mut moves = 0i64;
    let _ = analyze(nodes, root_index, &mut moves);
    moves
}
