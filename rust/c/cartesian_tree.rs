const MAX_N: usize = 128;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn cartesian_tree(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 1 + MAX_N {
        return -1;
    }
    let n_value = *input;
    if !(1..=MAX_N as i64).contains(&n_value) {
        return -1;
    }
    let n = n_value as usize;
    if length != n + 1 {
        return -1;
    }

    let mut parent = [0i64; MAX_N];
    let mut stack = [0usize; MAX_N];
    for i in 0..n {
        let key = *input.add(i + 1);
        if !(0..=1_000_000_000).contains(&key) {
            return -1;
        }
        parent[i] = i as i64;
    }

    let mut stack_size = 0;
    for i in 0..n {
        let mut last = MAX_N;
        while stack_size > 0 && *input.add(stack[stack_size - 1] + 1) > *input.add(i + 1) {
            stack_size -= 1;
            last = stack[stack_size];
        }
        if stack_size > 0 {
            parent[i] = stack[stack_size - 1] as i64;
        }
        if last < MAX_N {
            parent[last] = i as i64;
        }
        stack[stack_size] = i;
        stack_size += 1;
    }

    let output_bytes = n * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    for i in 0..n {
        store_i64_le(output, i * 8, parent[i]);
    }
    output_bytes as i64
}
