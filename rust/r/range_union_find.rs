const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_PARSEABLE_LENGTH: usize = 99;

fn find_root(parent: &mut [i64; MAX_N], mut vertex: usize) -> usize {
    while parent[vertex] >= 0 {
        let ancestor = parent[vertex] as usize;
        if parent[ancestor] >= 0 { parent[vertex] = parent[ancestor]; }
        vertex = ancestor;
    }
    vertex
}

fn unite_roots(
    parent: &mut [i64; MAX_N], left: &mut [i64; MAX_N], right: &mut [i64; MAX_N],
    mut root_a: usize, mut root_b: usize,
) -> usize {
    if parent[root_a] > parent[root_b] { std::mem::swap(&mut root_a, &mut root_b); }
    parent[root_a] += parent[root_b];
    parent[root_b] = root_a as i64;
    left[root_a] = left[root_a].min(left[root_b]);
    right[root_a] = right[root_a].max(right[root_b]);
    root_a
}

#[no_mangle]
pub unsafe extern "C" fn range_union_find(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_PARSEABLE_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let n_value = input[0];
    let q_value = input[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value)
        || length != 2 + 3 * q_value as usize { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    for operation in 0..q {
        let offset = 2 + 3 * operation;
        let (opcode, first, second) = (input[offset], input[offset + 1], input[offset + 2]);
        if opcode == 0 {
            if first < 0 || first > second || second > n_value { return -1; }
        } else if opcode == 1 {
            if first < 0 || first >= n_value || second < 0 || second >= n_value { return -1; }
        } else if opcode == 2 {
            if first < 0 || first >= n_value || second != 0 { return -1; }
        } else { return -1; }
    }

    let mut parent = [-1i64; MAX_N];
    let mut left = [0i64; MAX_N];
    let mut right = [0i64; MAX_N];
    for vertex in 0..n { left[vertex] = vertex as i64; right[vertex] = vertex as i64 + 1; }
    let mut components = n as i64;
    let mut total = 0i64;
    for operation in 0..q {
        let offset = 2 + 3 * operation;
        let opcode = input[offset] as i32;
        let first = input[offset + 1] as usize;
        let second = input[offset + 2] as usize;
        let observed: i64;
        if opcode == 0 {
            if first < second {
                let mut root = find_root(&mut parent, first);
                let mut next = right[root] as usize;
                while next < second {
                    let next_root = find_root(&mut parent, next);
                    if root == next_root { break; }
                    root = unite_roots(&mut parent, &mut left, &mut right, root, next_root);
                    components -= 1;
                    next = right[root] as usize;
                }
            }
            observed = components;
        } else if opcode == 1 {
            observed = (find_root(&mut parent, first) == find_root(&mut parent, second)) as i64;
        } else {
            observed = -parent[find_root(&mut parent, first)];
        }
        total += (operation as i64 + 1) * observed;
    }
    total
}
