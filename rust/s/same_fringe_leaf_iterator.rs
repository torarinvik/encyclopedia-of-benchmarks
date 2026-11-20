const MAX_TREE_NODES: usize = 15;
const MAX_TOTAL_NODES: usize = 30;
const MAX_PARSEABLE_LENGTH: usize = 93;

unsafe fn valid_tree(input: *const i64, offset: usize, node_count: usize) -> bool {
    let mut visited = [false; MAX_TREE_NODES];
    let mut parents = [0i64; MAX_TREE_NODES];
    let mut stack = [0usize; MAX_TREE_NODES];
    let mut top = 1usize;
    let mut reached = 0usize;
    while top > 0 {
        top -= 1;
        let node = stack[top];
        if node >= node_count || visited[node] { return false; }
        visited[node] = true;
        reached += 1;
        let base = offset + 3 * node;
        let left = *input.add(base + 1);
        let right = *input.add(base + 2);
        if left == -1 && right == -1 { continue; }
        if left < 0 || right < 0 || left as usize >= node_count || right as usize >= node_count ||
            left == right || left == 0 || right == 0 { return false; }
        parents[left as usize] += 1;
        parents[right as usize] += 1;
        if parents[left as usize] != 1 || parents[right as usize] != 1 { return false; }
        stack[top] = right as usize;
        top += 1;
        stack[top] = left as usize;
        top += 1;
    }
    if reached != node_count || parents[0] != 0 { return false; }
    for node in 1..node_count {
        if parents[node] != 1 { return false; }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn same_fringe_leaf_iterator(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let n_a_word = *input;
    let n_b_word = *input.add(1);
    if n_a_word < 1 || n_a_word > MAX_TREE_NODES as i64 ||
        n_b_word < 1 || n_b_word > MAX_TREE_NODES as i64 { return -1; }
    let n_a = n_a_word as usize;
    let n_b = n_b_word as usize;
    if n_a + n_b > MAX_TOTAL_NODES || length != 2 + 3 * (n_a + n_b) { return -1; }
    let offset_a = 2usize;
    let offset_b = 2 + 3 * n_a;
    if !valid_tree(input, offset_a, n_a) || !valid_tree(input, offset_b, n_b) { return -1; }

    let mut stack_a = [0usize; MAX_TREE_NODES];
    let mut stack_b = [0usize; MAX_TREE_NODES];
    let mut top_a = 1usize;
    let mut top_b = 1usize;
    loop {
        let mut have_a = false;
        let mut have_b = false;
        let mut leaf_a = 0i64;
        let mut leaf_b = 0i64;
        while top_a > 0 && !have_a {
            top_a -= 1;
            let node = stack_a[top_a];
            let base = offset_a + 3 * node;
            let left = *input.add(base + 1);
            let right = *input.add(base + 2);
            if left == -1 {
                leaf_a = *input.add(base);
                have_a = true;
            } else {
                stack_a[top_a] = right as usize;
                top_a += 1;
                stack_a[top_a] = left as usize;
                top_a += 1;
            }
        }
        while top_b > 0 && !have_b {
            top_b -= 1;
            let node = stack_b[top_b];
            let base = offset_b + 3 * node;
            let left = *input.add(base + 1);
            let right = *input.add(base + 2);
            if left == -1 {
                leaf_b = *input.add(base);
                have_b = true;
            } else {
                stack_b[top_b] = right as usize;
                top_b += 1;
                stack_b[top_b] = left as usize;
                top_b += 1;
            }
        }
        if !have_a || !have_b { return if have_a == have_b { 1 } else { 0 }; }
        if leaf_a != leaf_b { return 0; }
    }
}
