const MAX_NODES: usize = 64;
const MAX_INPUT_VALUES: usize = 2 + 3 * (MAX_NODES - 1);

fn matching_dp(node: usize, parent: isize, count: usize,
    adjacent: &[[bool; MAX_NODES]; MAX_NODES], weight: &[[i64; MAX_NODES]; MAX_NODES],
    visited: &mut [bool; MAX_NODES], parent_of: &mut [isize; MAX_NODES],
    without_edge: &mut [i64; MAX_NODES], with_edge: &mut [i64; MAX_NODES], reached: &mut usize) {
    visited[node] = true;
    parent_of[node] = parent;
    *reached += 1;
    let mut base = 0_i64;
    for child in 0..count {
        if adjacent[node][child] && child as isize != parent && !visited[child] {
            matching_dp(child, node as isize, count, adjacent, weight, visited, parent_of,
                without_edge, with_edge, reached);
            base += without_edge[child].max(with_edge[child]);
        }
    }
    without_edge[node] = base;
    with_edge[node] = 0;
    for child in 0..count {
        if parent_of[child] == node as isize {
            let child_best = without_edge[child].max(with_edge[child]);
            let candidate = base - child_best + without_edge[child] + weight[node][child];
            with_edge[node] = with_edge[node].max(candidate);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn tree_matching(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if !(1..=MAX_NODES as i64).contains(&values[0]) { return -1; }
    let count = values[0] as usize;
    if length != 2 + 3 * (count - 1) || values[1] < 0 || values[1] >= count as i64 { return -1; }
    let mut adjacent = [[false; MAX_NODES]; MAX_NODES];
    let mut weight = [[0_i64; MAX_NODES]; MAX_NODES];
    for edge in 0..count - 1 {
        let a_value = values[2 + 3 * edge];
        let b_value = values[3 + 3 * edge];
        let w = values[4 + 3 * edge];
        if a_value < 0 || b_value < 0 || a_value >= count as i64 || b_value >= count as i64 ||
            a_value == b_value || !(0..=1000).contains(&w) { return -1; }
        let a = a_value as usize;
        let b = b_value as usize;
        if adjacent[a][b] { return -1; }
        adjacent[a][b] = true; adjacent[b][a] = true;
        weight[a][b] = w; weight[b][a] = w;
    }
    let mut visited = [false; MAX_NODES];
    let mut parent_of = [-2_isize; MAX_NODES];
    let mut without_edge = [0_i64; MAX_NODES];
    let mut with_edge = [0_i64; MAX_NODES];
    let mut reached = 0;
    let root = values[1] as usize;
    matching_dp(root, -1, count, &adjacent, &weight, &mut visited, &mut parent_of,
        &mut without_edge, &mut with_edge, &mut reached);
    if reached != count { return -1; }
    without_edge[root].max(with_edge[root])
}
