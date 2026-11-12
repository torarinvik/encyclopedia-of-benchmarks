const MAX_N: usize = 5;
const MAX_P: usize = 32;
const MAX_INPUT: usize = 66;
const MAX_OUTPUT: usize = 256;
const MOD: i64 = 998_244_353;

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn mul_mod2n_convolution(input: *const i64, length: usize,
                                                output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 0 || words[0] as usize > MAX_N { return -1; }
    let p = 1usize << words[0] as usize;
    if length != 1 + 2 * p || words[1..].iter().any(|&x| x < 0 || x >= MOD) { return -1; }
    let bytes = 8 * p;
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    let mut a = [0i64; MAX_P];
    let mut b = [0i64; MAX_P];
    let mut result = [0i64; MAX_P];
    for i in 0..p { a[i] = words[1 + i]; b[i] = words[1 + p + i]; }
    let mask = p - 1;
    for i in 0..p { for j in 0..p {
        let k = (i * j) & mask;
        result[k] = (result[k] + a[i] * b[j]) % MOD;
    }}
    for i in 0..p { store_le(output, 8 * i, result[i]); }
    bytes as i64
}
