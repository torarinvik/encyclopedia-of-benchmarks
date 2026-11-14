#[no_mangle]
pub unsafe extern "C" fn xor_leaf_tree_traversal(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let n_raw = *input;
    if !(1..=64).contains(&n_raw) { return -1; }
    let n = n_raw as usize;
    let root_raw = *input.add(1);
    if root_raw < 0 || root_raw >= n_raw || length != 2 * n { return -1; }
    let root = root_raw as usize;
    let mut degree = [0i32; 64];
    let mut edge_xor = [0usize; 64];
    let mut endpoints = [(0usize, 0usize); 63];
    let mut dsu = [0usize; 64];
    let mut ranks = [0u8; 64];
    let mut parents = [-1i64; 64];
    let mut order = [0i64; 64];
    for (i, slot) in dsu.iter_mut().enumerate().take(n) { *slot = i; }
    for e in 0..n - 1 {
        let u = *input.add(2 + 2 * e);
        let v = *input.add(3 + 2 * e);
        if u < 0 || u >= n_raw || v < 0 || v >= n_raw || u == v { return -1; }
        let (u, v) = (u as usize, v as usize);
        let (mut x, mut y) = (u, v);
        while dsu[x] != x { dsu[x] = dsu[dsu[x]]; x = dsu[x]; }
        while dsu[y] != y { dsu[y] = dsu[dsu[y]]; y = dsu[y]; }
        if x == y { return -1; }
        if ranks[x] < ranks[y] { dsu[x] = y; }
        else { dsu[y] = x; if ranks[x] == ranks[y] { ranks[x] += 1; } }
        endpoints[e] = (u, v);
        degree[u] += 1; degree[v] += 1; edge_xor[u] ^= e; edge_xor[v] ^= e;
    }
    degree[root] = 0;
    let mut used = 0;
    for start in 0..n {
        let mut v = start;
        while degree[v] == 1 {
            let e = edge_xor[v];
            let next = endpoints[e].0 ^ endpoints[e].1 ^ v;
            parents[v] = e as i64; order[used] = v as i64; used += 1;
            degree[v] = 0; degree[next] -= 1; edge_xor[next] ^= e; v = next;
        }
    }
    order[used] = root as i64; used += 1;
    if used != n { return -1; }
    let bytes = 16 * n;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..2 * n {
        let word = if i < n { parents[i] } else { order[i - n] };
        for (b, value) in word.to_le_bytes().iter().enumerate() { *output.add(8 * i + b) = *value; }
    }
    bytes as i64
}
