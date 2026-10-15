const MAX_NODE_COUNT: usize = 1023;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub unsafe extern "C" fn lowest_common_ancestor(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 { return INVALID_RESULT; }
    let count_arg = *input;
    if !(2..=MAX_NODE_COUNT as i64).contains(&count_arg) { return INVALID_RESULT; }
    let count = count_arg as usize;
    if length != 4 + 3 * count { return INVALID_RESULT; }
    let root_arg = *input.add(1);
    let p_arg = *input.add(2);
    let q_arg = *input.add(3);
    if root_arg < 0 || root_arg >= count as i64 || p_arg < 0 || p_arg >= count as i64 ||
        q_arg < 0 || q_arg >= count as i64 || p_arg == q_arg { return INVALID_RESULT; }
    let root = root_arg as usize;
    let p = p_arg as usize;
    let q = q_arg as usize;

    let mut parent = [-1i64; MAX_NODE_COUNT];
    let mut stack = [0usize; MAX_NODE_COUNT];
    let mut path_p = [0usize; MAX_NODE_COUNT];
    let mut path_q = [0usize; MAX_NODE_COUNT];
    let mut seen = [false; MAX_NODE_COUNT];
    for node in 0..count {
        let offset = 4 + 3 * node;
        let value = *input.add(offset);
        if !(-1_000_000_000..=1_000_000_000).contains(&value) { return INVALID_RESULT; }
        for edge in 1..=2 {
            let child = *input.add(offset + edge);
            if child < -1 || (child >= 0 && child >= count as i64) { return INVALID_RESULT; }
            if child >= 0 {
                let child_index = child as usize;
                if parent[child_index] != -1 { return INVALID_RESULT; }
                parent[child_index] = node as i64;
            }
        }
    }
    if parent[root] != -1 { return INVALID_RESULT; }
    for node in 0..count {
        if node != root && parent[node] == -1 { return INVALID_RESULT; }
    }

    let mut top = 0usize;
    let mut reached = 0usize;
    stack[top] = root;
    top += 1;
    while top > 0 {
        top -= 1;
        let node = stack[top];
        if seen[node] { return INVALID_RESULT; }
        seen[node] = true;
        reached += 1;
        let offset = 4 + 3 * node;
        for edge in 1..=2 {
            let child = *input.add(offset + edge);
            if child >= 0 {
                stack[top] = child as usize;
                top += 1;
            }
        }
    }
    if reached != count { return INVALID_RESULT; }

    let mut depth_p = 0usize;
    let mut depth_q = 0usize;
    let mut current = p;
    path_p[depth_p] = current;
    depth_p += 1;
    while current != root {
        current = parent[current] as usize;
        path_p[depth_p] = current;
        depth_p += 1;
    }
    current = q;
    path_q[depth_q] = current;
    depth_q += 1;
    while current != root {
        current = parent[current] as usize;
        path_q[depth_q] = current;
        depth_q += 1;
    }
    let mut ancestor = INVALID_RESULT;
    while depth_p > 0 && depth_q > 0 && path_p[depth_p - 1] == path_q[depth_q - 1] {
        ancestor = path_p[depth_p - 1] as i64;
        depth_p -= 1;
        depth_q -= 1;
    }
    ancestor
}
