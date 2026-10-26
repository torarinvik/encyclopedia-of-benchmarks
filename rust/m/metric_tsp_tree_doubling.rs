const MAX_N: usize = 8;
const MAX_INPUT: usize = 65;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *output.add(offset + b) = (bits >> (8 * b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn metric_tsp_tree_doubling(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    if n64 < 1 || n64 > MAX_N as i64 || length != 1 + (n64 * n64) as usize { return -1; }
    let n = n64 as usize;
    let mut d = [[0i64; MAX_N]; MAX_N];
    for u in 0..n {
        for v in 0..n {
            let w = *input.add(1 + u * n + v);
            if !(0..=10000).contains(&w) || (u == v && w != 0) { return -1; }
            d[u][v] = w;
        }
    }
    for u in 0..n { for v in (u+1)..n { if d[u][v] != d[v][u] { return -1; } } }
    for u in 0..n { for v in 0..n { for k in 0..n { if d[u][v] > d[u][k] + d[k][v] { return -1; } } } }
    let output_bytes = 8 * (n + 2);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut processed = [[false; MAX_N]; MAX_N];
    let mut tree = [[false; MAX_N]; MAX_N];
    let mut parent = [0usize; MAX_N];
    for i in 0..n { parent[i] = i; }
    let mut accepted = 0;
    let edge_count = n * (n - 1) / 2;
    for _ in 0..edge_count {
        if accepted + 1 >= n { break; }
        let (mut bu, mut bv, mut bw) = (0usize, 0usize, i64::MAX);
        for u in 0..n { for v in (u+1)..n {
            if !processed[u][v] && d[u][v] < bw { bu = u; bv = v; bw = d[u][v]; }
        } }
        processed[bu][bv] = true;
        let (mut ru, mut rv) = (bu, bv);
        while parent[ru] != ru { ru = parent[ru]; }
        while parent[rv] != rv { rv = parent[rv]; }
        if ru != rv { parent[rv] = ru; tree[bu][bv] = true; tree[bv][bu] = true; accepted += 1; }
    }
    let mut stack = [0usize; MAX_N];
    let mut order = [0usize; MAX_N];
    let mut visited = [false; MAX_N];
    let (mut top, mut count) = (1usize, 0usize);
    stack[0] = 0;
    while top > 0 {
        top -= 1;
        let v = stack[top];
        if visited[v] { continue; }
        visited[v] = true;
        order[count] = v;
        count += 1;
        for rev in (0..n).rev() {
            if tree[v][rev] && !visited[rev] { stack[top] = rev; top += 1; }
        }
    }
    let mut cost = 0i64;
    for i in 0..(n - 1) { cost += d[order[i]][order[i + 1]]; }
    cost += d[order[n - 1]][0];
    store_i64_le(output, 0, cost);
    for i in 0..n { store_i64_le(output, 8 * (i + 1), order[i] as i64); }
    store_i64_le(output, 8 * (n + 1), 0);
    output_bytes as i64
}
