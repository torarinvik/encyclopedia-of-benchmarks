const MAX_NODES: usize = 1023;
const MAX_ARCS: usize = 2 * (MAX_NODES - 1);

fn dfs_height(node: usize, head: &[i64; MAX_NODES + 1], to: &[usize; MAX_ARCS],
    next: &[i64; MAX_ARCS], visited: &mut [bool; MAX_NODES + 1],
    dp: &mut [i64; MAX_NODES + 1], reached: &mut usize) -> i64 {
    visited[node] = true;
    *reached += 1;
    let mut child_height = 1;
    let mut arc = head[node];
    while arc >= 0 {
        let child = to[arc as usize];
        if !visited[child] {
            if dfs_height(child, head, to, next, visited, dp, reached) < 0 { return -1; }
            child_height = child_height.max(dp[child] + 1);
        }
        arc = next[arc as usize];
    }
    dp[node] = child_height;
    child_height
}

#[no_mangle]
pub unsafe extern "C" fn tree_height(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 { return -1; }
    let n_value = *values;
    if !(1..=MAX_NODES as i64).contains(&n_value) { return -1; }
    let count = n_value as usize;
    if length != 1 + 2 * (count - 1) { return -1; }
    let mut head = [-1_i64; MAX_NODES + 1];
    let mut to = [0_usize; MAX_ARCS];
    let mut next = [0_i64; MAX_ARCS];
    let mut dp = [0_i64; MAX_NODES + 1];
    let mut visited = [false; MAX_NODES + 1];
    let mut arcs = 0;
    for edge in 0..count - 1 {
        let a_value = *values.add(1 + 2 * edge);
        let b_value = *values.add(2 + 2 * edge);
        if a_value < 1 || b_value < 1 || a_value > count as i64 || b_value > count as i64 || a_value == b_value { return -1; }
        let a = a_value as usize; let b = b_value as usize;
        to[arcs] = b; next[arcs] = head[a]; head[a] = arcs as i64; arcs += 1;
        to[arcs] = a; next[arcs] = head[b]; head[b] = arcs as i64; arcs += 1;
    }
    let mut reached = 0;
    let result = dfs_height(1, &head, &to, &next, &mut visited, &mut dp, &mut reached);
    if result < 0 || reached != count { -1 } else { result }
}
