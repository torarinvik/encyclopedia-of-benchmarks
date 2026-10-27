const MAX_N: usize = 8;
const INF: i64 = 1_000_000;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for index in 0..8 { *output.add(offset + index) = bytes[index]; }
}

#[no_mangle]
pub unsafe extern "C" fn apsp_min_plus_repeated_squaring(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 65 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 1 || words[0] > MAX_N as i64 { return -1; }
    let n = words[0] as usize;
    if length != 1 + n * n { return -1; }
    let mut current = [0i64; MAX_N * MAX_N];
    let mut next = [0i64; MAX_N * MAX_N];
    for i in 0..n {
        for j in 0..n {
            let value = words[1 + i * n + j];
            if (i == j && value != 0)
                || (i != j && value != INF && (value < 1 || value > 1000)) { return -1; }
            current[i * n + j] = value;
        }
    }
    let mut edge_bound = 1usize;
    while edge_bound < n - 1 {
        for i in 0..n {
            for j in 0..n {
                let mut best = INF;
                for k in 0..n {
                    let left = current[i * n + k];
                    let right = current[k * n + j];
                    if left != INF && right != INF && left + right < best { best = left + right; }
                }
                next[i * n + j] = best;
            }
        }
        current[..n * n].copy_from_slice(&next[..n * n]);
        edge_bound *= 2;
    }
    let bytes = 8 * n * n;
    if output.is_null() || capacity < bytes { return -2; }
    for index in 0..n * n { store_i64_le(output, 8 * index, current[index]); }
    bytes as i64
}
