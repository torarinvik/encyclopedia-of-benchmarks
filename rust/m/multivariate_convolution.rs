const MAX_K: usize = 3;
const MAX_P: usize = 32;
const MAX_INPUT: usize = 69;
const MAX_OUTPUT: usize = 256;
const MOD: i64 = 998_244_353;
unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *output.add(offset + b) = ((bits >> (8 * b)) & 255) as u8; }
}
#[no_mangle]
pub unsafe extern "C" fn multivariate_convolution(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 0 || words[0] as usize > MAX_K { return -1; }
    let k = words[0] as usize; if length < 1 + k { return -1; }
    let mut dims = [0usize; MAX_K]; let mut p = 1usize;
    for axis in 0..k {
        let d0 = words[1 + axis];
        if d0 < 2 || d0 as usize > MAX_P || p > MAX_P / d0 as usize { return -1; }
        dims[axis] = d0 as usize; p *= dims[axis];
    }
    let start = 1 + k; if length != start + 2 * p { return -1; }
    if words[start..].iter().any(|&x| x < 0 || x >= MOD) { return -1; }
    let bytes = 8 * p; if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    let mut a = [0i64; MAX_P]; let mut b = [0i64; MAX_P]; let mut result = [0i64; MAX_P];
    for i in 0..p { a[i] = words[start + i]; b[i] = words[start + p + i]; }
    for i in 0..p { for j in 0..p {
        let mut target = 0usize; let mut stride = 1usize; let mut valid = true;
        for axis in 0..k {
            let d = dims[axis]; let sum = (i / stride) % d + (j / stride) % d;
            if sum >= d { valid = false; break; }
            target += sum * stride; stride *= d;
        }
        if valid { result[target] = (result[target] + a[i] * b[j]) % MOD; }
    }}
    for i in 0..p { store_le(output, 8 * i, result[i]); }
    bytes as i64
}
