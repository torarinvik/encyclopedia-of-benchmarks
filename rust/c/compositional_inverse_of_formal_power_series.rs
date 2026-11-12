const MODULUS: i64 = 998_244_353;
const MIN_N: usize = 2;
const MAX_N: usize = 16;
const MAX_INPUT: usize = 18;

fn mod_power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1_i64;
    while exponent > 0 {
        if exponent % 2 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent /= 2;
    }
    result
}

unsafe fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn compositional_inverse_of_formal_power_series(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < MIN_N + 1 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < MIN_N as i64 || input[0] > MAX_N as i64 { return -1; }
    let n = input[0] as usize;
    if length != n + 1 { return -1; }
    if input[1..].iter().any(|&value| value < 0 || value >= MODULUS) { return -1; }
    if input[1] != 0 || input[2] == 0 { return -1; }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }

    let mut powers = [0_i64; MAX_N * MAX_N];
    let mut inverse_series = [0_i64; MAX_N];
    let inverse_linear = mod_power(input[2], MODULUS - 2);
    inverse_series[1] = inverse_linear;
    powers[MAX_N + 1] = inverse_linear;
    for degree in 2..n {
        for power in 2..=degree {
            let mut coefficient = 0_i64;
            for split in 1..degree {
                coefficient = (coefficient + powers[(power - 1) * MAX_N + degree - split] *
                    inverse_series[split]) % MODULUS;
            }
            powers[power * MAX_N + degree] = coefficient;
        }
        let mut composed_coefficient = 0_i64;
        for power in 2..=degree {
            composed_coefficient = (composed_coefficient + input[power + 1] *
                powers[power * MAX_N + degree]) % MODULUS;
        }
        inverse_series[degree] = (MODULUS - composed_coefficient) * inverse_linear % MODULUS;
        powers[MAX_N + degree] = inverse_series[degree];
    }
    for i in 0..n { unsafe { store_le(output, 8 * i, inverse_series[i]); } }
    bytes as i64
}
