const MAX_INPUT: usize = 259;
const MAX_OUTPUT: usize = 2040;
const MAX_N: usize = 128;
const MAX_M: usize = 128;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
}

fn is_convex(values: &[i64]) -> bool {
    values.windows(3).all(|triple| triple[1] - triple[0] <= triple[2] - triple[1])
}

#[no_mangle]
pub unsafe extern "C" fn min_plus_convolution_convex_convex(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n0 = words[0];
    let m0 = words[1];
    if !(1..=MAX_N as i64).contains(&n0) || !(1..=MAX_M as i64).contains(&m0) { return -1; }
    let n = n0 as usize;
    let m = m0 as usize;
    if length != 2 + n + m { return -1; }
    let a = &words[2..2 + n];
    let b = &words[2 + n..];
    if words[2..].iter().any(|&value| !(0..=1_000_000_000).contains(&value))
        || !is_convex(a) || !is_convex(b) { return -1; }

    let count = n + m - 1;
    let bytes = 8 * count;
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }

    let mut result = [0i64; MAX_N + MAX_M - 1];
    result[0] = a[0] + b[0];
    let mut ai = 0;
    let mut bi = 0;
    let mut out = 1;
    while ai + 1 < n || bi + 1 < m {
        let slope;
        if bi + 1 == m || (ai + 1 < n && a[ai + 1] - a[ai] <= b[bi + 1] - b[bi]) {
            slope = a[ai + 1] - a[ai];
            ai += 1;
        } else {
            slope = b[bi + 1] - b[bi];
            bi += 1;
        }
        result[out] = result[out - 1] + slope;
        out += 1;
    }
    for index in 0..count { store_i64_le(output, 8 * index, result[index]); }
    bytes as i64
}
