/// Return the source's count of removable even subtrees, excluding the root.
#[no_mangle]
pub extern "C" fn even_tree(values: *const i64, length: usize) -> i64 {
    const INVALID: i64 = i64::MIN;
    const MAX_N: usize = 100;
    if values.is_null() || length < 2 { return INVALID; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (n_value, edge_value) = (values[0], values[1]);
    if !(2..=MAX_N as i64).contains(&n_value) || n_value % 2 != 0 || edge_value != n_value - 1 { return INVALID; }
    let (n, edge_count) = (n_value as usize, edge_value as usize);
    if length != 2 + 2 * edge_count { return INVALID; }
    let mut adjacency = [[false; MAX_N]; MAX_N];
    for i in 0..edge_count {
        let (u_value, v_value) = (values[2 + 2 * i], values[3 + 2 * i]);
        if u_value < 1 || u_value > n_value || v_value < 1 || v_value > n_value || u_value == v_value { return INVALID; }
        let (u, v) = ((u_value - 1) as usize, (v_value - 1) as usize);
        if adjacency[u][v] { return INVALID; }
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    let mut parents = [-2i32; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut order = [0usize; MAX_N];
    let mut subtree = [1i64; MAX_N];
    parents[0] = -1;
    let mut top = 1usize;
    let mut order_count = 0usize;
    stack[0] = 0;
    while top > 0 {
        top -= 1;
        let u = stack[top];
        order[order_count] = u;
        order_count += 1;
        for v in 0..n {
            if adjacency[u][v] && parents[v] == -2 {
                parents[v] = u as i32;
                stack[top] = v;
                top += 1;
            }
        }
    }
    if order_count != n { return INVALID; }
    let mut cuts = 0i64;
    for index in (0..order_count).rev() {
        let u = order[index];
        if parents[u] >= 0 { subtree[parents[u] as usize] += subtree[u]; }
        if subtree[u] % 2 == 0 { cuts += 1; }
    }
    cuts - 1
}
