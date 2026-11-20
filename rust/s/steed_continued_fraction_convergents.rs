const MODULUS: i64 = 998_244_353;

fn mod_pow(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn divisors_are_nonzero(values: &[i64], levels: usize) -> bool {
    if values[2] == 0 { return false; }
    let mut d_value = mod_pow(values[2], MODULUS - 2);
    for level in 2..=levels {
        let denominator = (d_value * values[2 * level + 1] + values[2 * level]) % MODULUS;
        if denominator == 0 { return false; }
        d_value = mod_pow(denominator, MODULUS - 2);
    }
    true
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn steed_continued_fraction_convergents(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(4..=19).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let levels_value = values[0];
    if !(1..=8).contains(&levels_value) || length != 2 + 2 * levels_value as usize {
        return -1;
    }
    if values[1..].iter().any(|&value| !(0..MODULUS).contains(&value)) { return -1; }
    let levels = levels_value as usize;
    if !divisors_are_nonzero(values, levels) { return -1; }
    let required = 8 * (levels + 2);
    if output.is_null() || capacity < required { return -2; }

    store_i64_le(output, 0, levels_value + 1);
    let mut current = values[1];
    store_i64_le(output, 8, current);
    let mut d_value = mod_pow(values[2], MODULUS - 2);
    let mut delta = values[3] * d_value % MODULUS;
    current = (current + delta) % MODULUS;
    store_i64_le(output, 16, current);
    for level in 2..=levels {
        let b_value = values[2 * level];
        let a_value = values[2 * level + 1];
        let denominator = (d_value * a_value + b_value) % MODULUS;
        d_value = mod_pow(denominator, MODULUS - 2);
        let factor = (b_value * d_value + MODULUS - 1) % MODULUS;
        delta = factor * delta % MODULUS;
        current = (current + delta) % MODULUS;
        store_i64_le(output, 8 * (level + 1), current);
    }
    required as i64
}
