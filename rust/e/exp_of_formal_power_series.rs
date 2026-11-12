const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_INPUT: usize = 66;

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn exp_of_formal_power_series(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != n + 1 { return -1; }
    if input[1..].iter().any(|&value| value < 0 || value >= MODULUS) || input[1] != 0 { return -1; }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }

    let mut integer_inverse = [0_i64; MAX_N];
    let mut exponential = [0_i64; MAX_N];
    if n > 1 { integer_inverse[1] = 1; }
    for k in 2..n {
        integer_inverse[k] = MODULUS - (MODULUS / k as i64) * integer_inverse[(MODULUS % k as i64) as usize] % MODULUS;
    }
    exponential[0] = 1;
    for degree in 1..n {
        let mut sum = 0_i64;
        for i in 1..=degree {
            let mut term = (i as i64 * input[i + 1]) % MODULUS;
            term = term * exponential[degree - i] % MODULUS;
            sum = (sum + term) % MODULUS;
        }
        exponential[degree] = sum * integer_inverse[degree] % MODULUS;
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, exponential[i]); } }
    bytes as i64
}
