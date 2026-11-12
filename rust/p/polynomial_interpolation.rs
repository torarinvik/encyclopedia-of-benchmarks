const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 12;
const MAX_INPUT: usize = 25;

fn normalize(value: i64) -> i64 {
    let reduced = value % MODULUS;
    if reduced < 0 { reduced + MODULUS } else { reduced }
}

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
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn polynomial_interpolation(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != 1 + 2 * n { return -1; }
    let xs = &input[1..1 + n];
    let ys = &input[1 + n..];
    for i in 0..n {
        if xs[i] < 0 || xs[i] >= MODULUS || ys[i] < 0 || ys[i] >= MODULUS { return -1; }
        for j in 0..i { if xs[i] == xs[j] { return -1; } }
    }

    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut result = [0_i64; MAX_N];
    for i in 0..n {
        let mut basis = [0_i64; MAX_N + 1];
        basis[0] = 1;
        let mut degree = 0;
        let mut denominator = 1_i64;
        for j in 0..n {
            if j == i { continue; }
            denominator = denominator * (xs[i] - xs[j]) % MODULUS;
            let mut expanded = [0_i64; MAX_N + 1];
            for k in 0..=degree {
                expanded[k] = normalize(expanded[k] - basis[k] * xs[j]);
                expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
            }
            for k in 0..=degree + 1 { basis[k] = expanded[k]; }
            degree += 1;
        }
        let scale = ys[i] * power_mod(normalize(denominator), MODULUS - 2) % MODULUS;
        for k in 0..n { result[k] = (result[k] + scale * basis[k]) % MODULUS; }
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, result[i]); } }
    bytes as i64
}
