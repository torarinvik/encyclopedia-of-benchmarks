const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_LEVELS: usize = 6;
const MODULUS: i64 = 998_244_353;

type Layers = [[usize; MAX_N]; MAX_LEVELS];

fn normalize(value: i64) -> i64 { value.rem_euclid(MODULUS) }

fn find_root(parent: &mut Layers, level: usize, item: usize) -> usize {
    if parent[level][item] != item {
        parent[level][item] = find_root(parent, level, parent[level][item]);
    }
    parent[level][item]
}

fn merge_inner(level: usize, left: usize, right: usize, parent: &mut Layers,
    set_size: &mut Layers, weight: &mut [i64; MAX_N], pair_sum: &mut i64) {
    let mut root_left = find_root(parent, level, left);
    let mut root_right = find_root(parent, level, right);
    if root_left == root_right { return; }
    if set_size[level][root_left] < set_size[level][root_right] {
        std::mem::swap(&mut root_left, &mut root_right);
    }
    parent[level][root_right] = root_left;
    set_size[level][root_left] += set_size[level][root_right];
    if level == 0 {
        *pair_sum = normalize(*pair_sum + weight[root_left] * weight[root_right]);
        weight[root_left] = normalize(weight[root_left] + weight[root_right]);
        return;
    }
    let half = 1usize << (level - 1);
    merge_inner(level - 1, left, right, parent, set_size, weight, pair_sum);
    merge_inner(level - 1, left + half, right + half, parent, set_size, weight, pair_sum);
}

fn floor_log2(value: usize) -> usize {
    let mut level = 0;
    let mut remaining = value;
    while remaining > 1 { remaining >>= 1; level += 1; }
    level
}

fn merge_ranges(length: usize, left: usize, right: usize, parent: &mut Layers,
    set_size: &mut Layers, weight: &mut [i64; MAX_N], pair_sum: &mut i64) {
    if length == 0 { return; }
    let level = floor_log2(length - 1);
    let block = 1usize << level;
    merge_inner(level, left, right, parent, set_size, weight, pair_sum);
    merge_inner(level, left + length - block, right + length - block, parent, set_size, weight, pair_sum);
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn range_parallel_unionfind(input: *const i64,
    length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > 2 + MAX_N + 3 * MAX_Q { return -1; }
    let n_value = *input;
    let q_value = *input.add(1);
    if n_value < 1 || n_value > MAX_N as i64 || q_value < 1 || q_value > MAX_Q as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + n + 3 * q { return -1; }
    for item in 0..n {
        let weight = *input.add(2 + item);
        if !(0..MODULUS).contains(&weight) { return -1; }
    }
    let operations_at = 2 + n;
    for operation in 0..q {
        let position = operations_at + 3 * operation;
        let span = *input.add(position);
        let left = *input.add(position + 1);
        let right = *input.add(position + 2);
        if span < 0 || span > n_value || left < 0 || right < 0 ||
            left > n_value - span || right > n_value - span { return -1; }
    }
    let required = 8 * q;
    if output.is_null() || capacity < required { return -2; }

    let mut parent = [[0usize; MAX_N]; MAX_LEVELS];
    let mut set_size = [[0usize; MAX_N]; MAX_LEVELS];
    for level in 0..MAX_LEVELS {
        let block = 1usize << level;
        if block > n { break; }
        for start in 0..=n - block {
            parent[level][start] = start;
            set_size[level][start] = 1;
        }
    }
    let mut weight = [0i64; MAX_N];
    for item in 0..n { weight[item] = *input.add(2 + item); }
    let mut pair_sum = 0i64;
    for operation in 0..q {
        let position = operations_at + 3 * operation;
        merge_ranges(*input.add(position) as usize, *input.add(position + 1) as usize,
            *input.add(position + 2) as usize, &mut parent, &mut set_size, &mut weight, &mut pair_sum);
        store_i64_le(output, 8 * operation, pair_sum);
    }
    required as i64
}
