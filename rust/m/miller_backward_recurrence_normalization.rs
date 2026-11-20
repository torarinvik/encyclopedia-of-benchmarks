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

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn miller_backward_recurrence_normalization(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(6..=35).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let levels_value = values[0];
    if !(1..=8).contains(&levels_value) || length != 4 * levels_value as usize + 2 {
        return -1;
    }
    if values[1..].iter().any(|&value| !(0..MODULUS).contains(&value)) { return -1; }
    let levels = levels_value as usize;
    for level in 1..=levels {
        if values[3 * level] == 0 { return -1; }
    }

    let mut trial = [0i64; 10];
    trial[levels] = 1;
    trial[levels + 1] = 0;
    for level in (1..=levels).rev() {
        let a_value = values[3 * level - 2];
        let b_value = values[3 * level - 1];
        let c_value = values[3 * level];
        let positive = b_value * trial[level] % MODULUS;
        let negative = a_value * trial[level + 1] % MODULUS;
        let numerator = (positive + MODULUS - negative) % MODULUS;
        trial[level - 1] = numerator * mod_pow(c_value, MODULUS - 2) % MODULUS;
    }
    let lambda_start = 3 * levels + 1;
    let mut normalizer = 0i64;
    for index in 0..=levels {
        normalizer = (normalizer + values[lambda_start + index] * trial[index]) % MODULUS;
    }
    if normalizer == 0 { return -1; }
    let scale = mod_pow(normalizer, MODULUS - 2);
    let required = 8 * (levels + 2);
    if output.is_null() || capacity < required { return -2; }

    store_i64_le(output, 0, levels_value);
    for index in 0..=levels {
        store_i64_le(output, 8 * (index + 1), trial[index] * scale % MODULUS);
    }
    required as i64
}
