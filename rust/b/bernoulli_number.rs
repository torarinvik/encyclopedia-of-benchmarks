const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 32;

fn modular_power(base_value: i64, exponent_value: i64) -> i64 {
    let (mut base, mut exponent, mut result) = (base_value, exponent_value, 1_i64);
    while exponent > 0 {
        if (exponent & 1) != 0 {
            result = result * base % MODULUS;
        }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn bernoulli_number(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    let n64 = *input;
    if n64 < 0 || n64 > MAX_N as i64 {
        return -1;
    }
    let n = n64 as usize;
    let output_bytes = 4 * (n + 1);
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut inverse = [0_i64; MAX_N + 2];
    let mut bernoulli = [0_i64; MAX_N + 1];
    inverse[1] = 1;
    for i in 2..=n + 1 {
        inverse[i] = modular_power(i as i64, MODULUS - 2);
    }

    bernoulli[0] = 1;
    for m in 1..=n {
        let (mut choose, mut total) = (1_i64, 0_i64);
        for k in 0..m {
            total = (total + choose * bernoulli[k]) % MODULUS;
            choose = choose * (m + 1 - k) as i64 % MODULUS * inverse[k + 1] % MODULUS;
        }
        bernoulli[m] = ((MODULUS - total) % MODULUS) * inverse[m + 1] % MODULUS;
    }

    for i in 0..=n {
        let value = bernoulli[i] as u32;
        *output.add(4 * i) = value as u8;
        *output.add(4 * i + 1) = (value >> 8) as u8;
        *output.add(4 * i + 2) = (value >> 16) as u8;
        *output.add(4 * i + 3) = (value >> 24) as u8;
    }
    output_bytes as i64
}
