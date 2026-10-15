const MAX_NODES: usize = 256;
const MAX_QUERIES: usize = 1024;
const MAX_ARCS: usize = 510;
const LOG_LEVELS: usize = 9;

#[no_mangle]
pub unsafe extern "C" fn lowest_common_ancestor_binary_lifting(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 { return -1; }
    let n_arg = *input;
    if !(1..=MAX_NODES as i64).contains(&n_arg) { return -1; }
    let n = n_arg as usize;
    let root_arg = *input.add(1);
    let edge_arg = *input.add(2);
    let query_arg = *input.add(3);
    if root_arg < 0 || root_arg >= n as i64 || edge_arg != (n - 1) as i64 ||
        query_arg < 0 || query_arg > MAX_QUERIES as i64 { return -1; }
    let m = edge_arg as usize;
    let q = query_arg as usize;
    let query_offset = 4 + 2 * m;
    if length != query_offset + 2 * q { return -1; }
    let root = root_arg as usize;
    let mut head = [-1i32; MAX_NODES];
    let mut arc_to = [0usize; MAX_ARCS];
    let mut arc_next = [-1i32; MAX_ARCS];
    let mut parent = [-2i64; MAX_NODES];
    let mut depth = [0usize; MAX_NODES];
    let mut up = [[0usize; MAX_NODES]; LOG_LEVELS];
    let mut stack = [0usize; MAX_NODES];
    let mut arcs = 0usize;
    for edge in 0..m {
        let left = *input.add(4 + 2 * edge);
        let right = *input.add(5 + 2 * edge);
        if left < 0 || left >= n as i64 || right < 0 || right >= n as i64 || left == right { return -1; }
        let a = left as usize;
        let b = right as usize;
        arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = arcs as i32; arcs += 1;
        arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = arcs as i32; arcs += 1;
    }
    for query in 0..q {
        for side in 0..2 {
            let node = *input.add(query_offset + 2 * query + side);
            if node < 0 || node >= n as i64 { return -1; }
        }
    }
    let mut top = 0usize;
    let mut reached = 0usize;
    parent[root] = -1; up[0][root] = root; stack[top] = root; top += 1;
    while top > 0 {
        top -= 1;
        let node = stack[top]; reached += 1;
        let mut arc = head[node];
        while arc >= 0 {
            let edge = arc as usize;
            let neighbor = arc_to[edge];
            if neighbor as i64 != parent[node] {
                if parent[neighbor] != -2 { return -1; }
                parent[neighbor] = node as i64;
                depth[neighbor] = depth[node] + 1;
                up[0][neighbor] = node;
                stack[top] = neighbor; top += 1;
            }
            arc = arc_next[edge];
        }
    }
    if reached != n { return -1; }
    if output_capacity < q || (q != 0 && output.is_null()) { return -2; }
    for level in 1..LOG_LEVELS {
        for node in 0..n { up[level][node] = up[level - 1][up[level - 1][node]]; }
    }
    for query in 0..q {
        let mut u = *input.add(query_offset + 2 * query) as usize;
        let mut v = *input.add(query_offset + 2 * query + 1) as usize;
        if depth[u] < depth[v] { std::mem::swap(&mut u, &mut v); }
        let difference = depth[u] - depth[v];
        for level in 0..LOG_LEVELS {
            if difference & (1usize << level) != 0 { u = up[level][u]; }
        }
        if u != v {
            for level in (0..LOG_LEVELS).rev() {
                if up[level][u] != up[level][v] { u = up[level][u]; v = up[level][v]; }
            }
            u = up[0][u];
        }
        *output.add(query) = u as u8;
    }
    q as i64
}
