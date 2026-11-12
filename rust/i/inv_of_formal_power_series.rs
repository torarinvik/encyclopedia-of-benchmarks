const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_INPUT: usize = 66;

fn power_mod(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn inv_of_formal_power_series(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != n + 1 { return -1; }
    if input[1..].iter().any(|&value| value < 0 || value >= MODULUS) || input[1] == 0 { return -1; }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }

    let mut inverse = [0_i64; MAX_N];
    let inverse_constant = power_mod(input[1], MODULUS - 2);
    inverse[0] = inverse_constant;
    for degree in 1..n {
        let mut sum = 0_i64;
        for i in 1..=degree { sum = (sum + input[i + 1] * inverse[degree - i]) % MODULUS; }
        inverse[degree] = (MODULUS - inverse_constant * sum % MODULUS) % MODULUS;
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, inverse[i]); } }
    bytes as i64
}
