const MAX_INPUT: usize = 130;
const MAX_OUTPUT: usize = 512;
const INF: i64 = 1_000_000;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn min_plus_distance_product(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n0 = words[0];
    let m0 = words[1];
    if n0 < 1 || n0 > 8 || m0 < 1 || m0 > 8 { return -1; }
    let n = n0 as usize;
    let m = m0 as usize;
    if length != 2 + 2 * n * m { return -1; }
    if words[2..].iter().any(|&x| x < 0 || (x > 1000 && x != INF)) { return -1; }
    let bytes = 8 * n * n;
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    let mut result = [0i64; 64];
    for i in 0..n {
        for j in 0..n {
            let mut best = INF;
            for k in 0..m {
                let x = words[2 + i * m + k];
                let y = words[2 + n * m + k * n + j];
                if x != INF && y != INF && x + y < best { best = x + y; }
            }
            result[i * n + j] = best;
        }
    }
    for i in 0..n * n { store_i64_le(output, 8 * i, result[i]); }
    bytes as i64
}
