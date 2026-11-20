const MAX_N: i64 = 32;
const MAX_Q: i64 = 64;
const MAX_INPUT_LENGTH: usize = 195;

fn find_parity(parent: &mut [i64; 32], parity: &mut [i64; 32], node: usize) -> (usize, i64) {
    let mut root = node;
    let mut total = 0i64;
    while parent[root] as usize != root { total ^= parity[root]; root = parent[root] as usize; }
    let mut current = node;
    let mut accumulated = 0i64;
    while parent[current] as usize != current {
        let next = parent[current] as usize;
        let edge = parity[current];
        parent[current] = root as i64;
        parity[current] = total ^ accumulated;
        accumulated ^= edge;
        current = next;
    }
    (root, total)
}

#[no_mangle]
pub unsafe extern "C" fn online_bipartiteness_dsu(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, q_value) = (values[0], values[1]);
    if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q { return -1; }
    let (n, q) = (n_value as usize, q_value as usize);
    if length != 2 + 3 * q { return -1; }
    for j in 0..q {
        let (opcode, a, b) = (values[2 + 3 * j], values[3 + 3 * j], values[4 + 3 * j]);
        if opcode == 0 { if a < 0 || a >= n_value || b < 0 || b >= n_value { return -1; } }
        else if opcode == 1 { if a < 0 || a >= n_value || b != 0 { return -1; } }
        else { return -1; }
    }
    let mut parent = [0i64; 32];
    let mut size = [0i64; 32];
    let mut parity = [0i64; 32];
    let mut bad = [false; 32];
    for i in 0..n { parent[i] = i as i64; size[i] = 1; }
    let mut checksum = 0i64;
    let mut query_ordinal = 0i64;
    for operation in 0..q {
        let opcode = values[2 + 3 * operation];
        let a = values[3 + 3 * operation] as usize;
        if opcode == 1 {
            let (root, _) = find_parity(&mut parent, &mut parity, a);
            let answer = if bad[root] { 0i64 } else { 1i64 };
            checksum += (query_ordinal + 1) * (answer + 1);
            query_ordinal += 1;
            continue;
        }
        let b = values[4 + 3 * operation] as usize;
        let (mut root_a, mut parity_a) = find_parity(&mut parent, &mut parity, a);
        let (mut root_b, mut parity_b) = find_parity(&mut parent, &mut parity, b);
        if root_a == root_b { if parity_a == parity_b { bad[root_a] = true; } continue; }
        if size[root_a] < size[root_b] { std::mem::swap(&mut root_a, &mut root_b); std::mem::swap(&mut parity_a, &mut parity_b); }
        parent[root_b] = root_a as i64;
        parity[root_b] = parity_a ^ parity_b ^ 1;
        size[root_a] += size[root_b];
        bad[root_a] = bad[root_a] || bad[root_b];
    }
    checksum
}
