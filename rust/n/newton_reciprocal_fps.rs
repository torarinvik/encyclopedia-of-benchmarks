const MODULUS: i64 = 998_244_353;

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn newton_reciprocal_fps(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=66).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1] == 0 || values[1..].iter().any(|&x| !(0..MODULUS).contains(&x)) {
        return -1;
    }
    let bytes = 8 * n;
    if output.is_null() || capacity < bytes { return -2; }
    let mut inverse = [0_i64; 64];
    inverse[0] = power(values[1], MODULUS - 2);
    let mut precision = 1;
    while precision < n {
        let width = (2 * precision).min(n);
        let mut correction = [0_i64; 64];
        for i in 0..width {
            for j in 0..precision.min(width - i) {
                correction[i + j] = (correction[i + j] + values[i + 1] * inverse[j]) % MODULUS;
            }
        }
        correction[0] = (2 + MODULUS - correction[0]) % MODULUS;
        for value in &mut correction[1..width] { *value = (MODULUS - *value) % MODULUS; }
        let mut next = [0_i64; 64];
        for i in 0..precision {
            for j in 0..width - i {
                next[i + j] = (next[i + j] + inverse[i] * correction[j]) % MODULUS;
            }
        }
        inverse = next;
        precision = width;
    }
    let destination = std::slice::from_raw_parts_mut(output, bytes);
    for (i, value) in inverse[..n].iter().enumerate() {
        destination[8 * i..8 * i + 8].copy_from_slice(&value.to_le_bytes());
    }
    bytes as i64
}
