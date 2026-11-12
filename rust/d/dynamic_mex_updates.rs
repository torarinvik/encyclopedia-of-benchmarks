const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_Q;

fn tree_set(tree: &mut [i32; 128], base: usize, value: usize, present: i32) {
    let mut node = base + value;
    tree[node] = present;
    node >>= 1;
    while node > 0 {
        tree[node] = tree[2 * node] + tree[2 * node + 1];
        node >>= 1;
    }
}

fn find_mex(tree: &[i32; 128], base: usize, domain_size: usize) -> usize {
    let (mut node, mut start, mut span) = (1, 0, base);
    while span > 1 {
        let half = span / 2;
        let left_width = if start >= domain_size { 0 } else { half.min(domain_size - start) };
        if (tree[2 * node] as usize) < left_width {
            node *= 2;
            span = half;
        } else {
            node = 2 * node + 1;
            start += half;
            span = half;
        }
    }
    start
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_mex_updates(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 99 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let q_value = values[1];
    if !(1..=MAX_N as i64).contains(&n_value) || !(0..=MAX_Q as i64).contains(&q_value) {
        return -1;
    }
    let n = n_value as usize;
    let q = q_value as usize;
    if length != 2 + n + 2 * q {
        return -1;
    }
    let mut current = [0_i64; MAX_N];
    let mut update_indices = [0_usize; MAX_Q];
    let mut update_values = [0_i64; MAX_Q];
    for index in 0..n {
        let value = values[2 + index];
        if !(-1000..=1000).contains(&value) {
            return -1;
        }
        current[index] = value;
    }
    let mut cursor = 2 + n;
    for operation in 0..q {
        let index = values[cursor];
        let value = values[cursor + 1];
        cursor += 2;
        if index < 0 || index >= n_value || !(-1000..=1000).contains(&value) {
            return -1;
        }
        update_indices[operation] = index as usize;
        update_values[operation] = value;
    }
    let needed = 8 * q;
    if needed > 0 && (output.is_null() || capacity < needed) {
        return -2;
    }

    let mut base = 1;
    while base < n + 1 {
        base *= 2;
    }
    let mut frequencies = [0_i32; MAX_N + 1];
    let mut tree = [0_i32; 128];
    for value in current.iter().take(n).copied() {
        if value >= 0 && value <= n_value {
            frequencies[value as usize] += 1;
        }
    }
    for value in 0..n + 1 {
        tree[base + value] = if frequencies[value] > 0 { 1 } else { 0 };
    }
    for node in (1..base).rev() {
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    for operation in 0..q {
        let index = update_indices[operation];
        let old_value = current[index];
        let new_value = update_values[operation];
        if old_value != new_value {
            if old_value >= 0 && old_value <= n_value {
                let old_index = old_value as usize;
                frequencies[old_index] -= 1;
                if frequencies[old_index] == 0 {
                    tree_set(&mut tree, base, old_index, 0);
                }
            }
            if new_value >= 0 && new_value <= n_value {
                let new_index = new_value as usize;
                if frequencies[new_index] == 0 {
                    tree_set(&mut tree, base, new_index, 1);
                }
                frequencies[new_index] += 1;
            }
            current[index] = new_value;
        }
        let answer = find_mex(&tree, base, n + 1) as i64;
        staged[8 * operation..8 * operation + 8].copy_from_slice(&answer.to_le_bytes());
    }
    for byte in 0..needed {
        *output.add(byte) = staged[byte];
    }
    needed as i64
}
