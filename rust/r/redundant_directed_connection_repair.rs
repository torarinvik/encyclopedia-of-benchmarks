const MAX_N: usize = 16;

fn find_root(parent: &mut [usize; MAX_N], mut node: usize) -> usize {
    while parent[node] != node {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    node
}

#[no_mangle]
pub unsafe extern "C" fn redundant_directed_connection_repair(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > 34 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(3..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + 2 * n { return -1; }
    let mut from = [0_usize; MAX_N];
    let mut to = [0_usize; MAX_N];
    for edge in 0..n {
        let (u, v) = (values[1 + 2 * edge], values[2 + 2 * edge]);
        if u < 0 || u >= n_value || v < 0 || v >= n_value || u == v { return -1; }
        from[edge] = u as usize;
        to[edge] = v as usize;
        for prior in 0..edge {
            if from[prior] == from[edge] && to[prior] == to[edge] { return -1; }
        }
    }
    let mut incoming = [-1_i32; MAX_N];
    let mut first_parent = -1_i32;
    let mut second_parent = -1_i32;
    for edge in 0..n {
        let child = to[edge];
        if incoming[child] < 0 { incoming[child] = edge as i32; }
        else { first_parent = incoming[child]; second_parent = edge as i32; break; }
    }
    let mut parent = [0_usize; MAX_N];
    let mut size = [1_usize; MAX_N];
    for node in 0..n { parent[node] = node; }
    let mut cycle_edge = -1_i32;
    for edge in 0..n {
        if edge as i32 == second_parent { continue; }
        let mut a = find_root(&mut parent, from[edge]);
        let mut b = find_root(&mut parent, to[edge]);
        if a == b { cycle_edge = edge as i32; break; }
        if size[a] < size[b] { std::mem::swap(&mut a, &mut b); }
        parent[b] = a;
        size[a] += size[b];
    }
    if cycle_edge >= 0 {
        if second_parent >= 0 { first_parent as i64 } else { cycle_edge as i64 }
    } else {
        second_parent as i64
    }
}
