const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 16;
const MAX_M: usize = 16;
const MAX_INPUT: usize = 20;

fn mod_pow(mut base: i64, mut exponent: i64) -> i64 {
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
pub unsafe extern "C" fn shift_of_sampling_points_of_polynomial(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 || input[1] < 1 || input[1] > MAX_M as i64 { return -1; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    let start = input[2];
    if length != n + 3 || start < 0 || start >= MODULUS { return -1; }
    for &sample in &input[3..] {
        if sample < 0 || sample >= MODULUS { return -1; }
    }
    let bytes = 8 * m;
    if output.is_null() || capacity < bytes { return -2; }

    let mut differences = [0_i64; MAX_N];
    let mut newton = [0_i64; MAX_N];
    let mut factorial = [0_i64; MAX_N];
    let mut inverse_factorial = [0_i64; MAX_N];
    differences[..n].copy_from_slice(&input[3..]);
    factorial[0] = 1;
    for k in 1..n { factorial[k] = factorial[k - 1] * k as i64 % MODULUS; }
    inverse_factorial[n - 1] = mod_pow(factorial[n - 1], MODULUS - 2);
    for k in (1..n).rev() { inverse_factorial[k - 1] = inverse_factorial[k] * k as i64 % MODULUS; }
    for k in 0..n {
        newton[k] = differences[0] * inverse_factorial[k] % MODULUS;
        for i in 0..(n - k - 1) {
            differences[i] = differences[i + 1] - differences[i];
            if differences[i] < 0 { differences[i] += MODULUS; }
        }
    }
    for offset in 0..m {
        let mut x = start + offset as i64;
        if x >= MODULUS { x -= MODULUS; }
        let mut basis = 1_i64;
        let mut value = 0_i64;
        for k in 0..n {
            value = (value + newton[k] * basis) % MODULUS;
            let mut factor = x - k as i64;
            if factor < 0 { factor += MODULUS; }
            basis = basis * factor % MODULUS;
        }
        unsafe { store_le(output, 8 * offset, value); }
    }
    bytes as i64
}
