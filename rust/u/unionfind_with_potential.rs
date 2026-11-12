const MAX_N: usize = 64;
const MAX_Q: usize = 256;
const MODULUS: i64 = 998_244_353;

fn normalize(value: i64) -> i64 {
    value.rem_euclid(MODULUS)
}

fn find_root(parent: &mut [usize; MAX_N], difference: &mut [i64; MAX_N], item: usize) -> usize {
    if parent[item] != item {
        let old_parent = parent[item];
        let root = find_root(parent, difference, old_parent);
        difference[item] = normalize(difference[item] + difference[old_parent]);
        parent[item] = root;
    }
    parent[item]
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn unionfind_with_potential(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > 2 + 4 * MAX_Q { return -1; }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + 4 * q { return -1; }

    for operation in 0..q {
        let position = 2 + 4 * operation;
        let kind = *input.add(position);
        let u = *input.add(position + 1);
        let v = *input.add(position + 2);
        let x = *input.add(position + 3);
        if u < 0 || u >= n_value || v < 0 || v >= n_value { return -1; }
        if kind == 0 {
            if x < 0 || x >= MODULUS { return -1; }
        } else if kind == 1 {
            if x != 0 { return -1; }
        } else { return -1; }
    }
    let required = 8 * q;
    if output.is_null() || capacity < required { return -2; }

    let mut parent = [0usize; MAX_N];
    let mut set_size = [0usize; MAX_N];
    let mut difference = [0i64; MAX_N];
    for item in 0..n { parent[item] = item; set_size[item] = 1; }
    for operation in 0..q {
        let position = 2 + 4 * operation;
        let kind = *input.add(position);
        let u = *input.add(position + 1) as usize;
        let v = *input.add(position + 2) as usize;
        let x = *input.add(position + 3);
        let root_u = find_root(&mut parent, &mut difference, u);
        let root_v = find_root(&mut parent, &mut difference, v);
        let answer: i64;
        if kind == 1 {
            answer = if root_u == root_v { normalize(difference[u] - difference[v]) } else { -1 };
        } else if root_u == root_v {
            answer = i64::from(normalize(difference[u] - difference[v]) == x);
        } else if set_size[root_u] < set_size[root_v] {
            parent[root_u] = root_v;
            difference[root_u] = normalize(x - difference[u] + difference[v]);
            set_size[root_v] += set_size[root_u];
            answer = 1;
        } else {
            parent[root_v] = root_u;
            difference[root_v] = normalize(difference[u] - difference[v] - x);
            set_size[root_u] += set_size[root_v];
            answer = 1;
        }
        store_i64_le(output, 8 * operation, answer);
    }
    required as i64
}
