const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 32;
const MAX_INPUT: usize = 34;
const MAX_EXPONENT: i64 = 1_000_000_000_000_000_000;
type Polynomial = [i64; MAX_N];

fn multiply_truncated(left: &Polynomial, right: &Polynomial, n: usize) -> Polynomial {
    let mut product = [0_i64; MAX_N];
    for i in 0..n {
        for j in 0..(n - i) {
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
        }
    }
    product
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn pow_of_formal_power_series(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 || input[1] < 0 || input[1] > MAX_EXPONENT { return -1; }
    let n = input[0] as usize;
    if length != n + 2 { return -1; }
    for i in 0..n { if input[i + 2] < 0 || input[i + 2] >= MODULUS { return -1; } }

    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut result = [0_i64; MAX_N];
    let mut base = [0_i64; MAX_N];
    result[0] = 1;
    for i in 0..n { base[i] = input[i + 2]; }
    let mut exponent = input[1];
    while exponent > 0 {
        if exponent & 1 != 0 { result = multiply_truncated(&result, &base, n); }
        exponent >>= 1;
        if exponent > 0 { base = multiply_truncated(&base, &base, n); }
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, result[i]); } }
    bytes as i64
}
