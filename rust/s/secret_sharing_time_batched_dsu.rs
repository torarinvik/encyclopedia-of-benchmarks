const MAX_N: usize = 16;
const MAX_M: usize = 20;

fn find_root(parent: &mut [usize; MAX_N], mut node: usize) -> usize {
    while parent[node] != node {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    node
}

fn join_sets(parent: &mut [usize; MAX_N], size: &mut [usize; MAX_N], left: usize, right: usize) {
    let mut a = find_root(parent, left);
    let mut b = find_root(parent, right);
    if a == b { return; }
    if size[a] < size[b] { std::mem::swap(&mut a, &mut b); }
    parent[b] = a;
    size[a] += size[b];
}

#[no_mangle]
pub unsafe extern "C" fn secret_sharing_time_batched_dsu(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > 64 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, first_value, m_value) = (values[0], values[1], values[2]);
    if !(2..=MAX_N as i64).contains(&n_value) || first_value < 1 || first_value >= n_value
        || !(0..=MAX_M as i64).contains(&m_value) { return -1; }
    let (n, first, m) = (n_value as usize, first_value as usize, m_value as usize);
    if length != 3 + 3 * m { return -1; }
    let mut parent = [0_usize; MAX_N];
    let mut size = [1_usize; MAX_N];
    for i in 0..n { parent[i] = i; }
    for i in 0..m {
        let (u, v, time) = (values[3 + 3*i], values[4 + 3*i], values[5 + 3*i]);
        if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v || !(1..=20).contains(&time) {
            return -1;
        }
    }
    join_sets(&mut parent, &mut size, 0, first);
    for time in 1..=20 {
        let mut touched = [false; MAX_N];
        for i in 0..m {
            let (u, v) = (values[3 + 3*i] as usize, values[4 + 3*i] as usize);
            if values[5 + 3*i] == time {
                join_sets(&mut parent, &mut size, u, v);
                touched[u] = true;
                touched[v] = true;
            }
        }
        let known_root = find_root(&mut parent, 0);
        for node in 0..n {
            if touched[node] && find_root(&mut parent, node) != known_root {
                parent[node] = node;
                size[node] = 1;
            }
        }
    }
    let known_root = find_root(&mut parent, 0);
    let mut result = 0_i64;
    for node in 0..n {
        if find_root(&mut parent, node) == known_root { result |= 1_i64 << node; }
    }
    result
}
