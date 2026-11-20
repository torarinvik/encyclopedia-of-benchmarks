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

fn numerator(coefficient: i64, rho: i64) -> i64 {
    coefficient * ((rho + 1) % MODULUS) % MODULUS
}

fn divisors_are_nonzero(values: &[i64], count: usize) -> bool {
    let mut rho = 0i64;
    for index in 1..count {
        let top = numerator(values[index + 1], rho);
        let denominator = (1 + MODULUS - top) % MODULUS;
        if denominator == 0 { return false; }
        rho = top * mod_pow(denominator, MODULUS - 2) % MODULUS;
    }
    true
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn continued_fraction_forward_series_recurrence(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=11).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    if !(2..=9).contains(&count_value) || length != count_value as usize + 1 { return -1; }
    if values[1..].iter().any(|&value| !(0..MODULUS).contains(&value)) { return -1; }
    let count = count_value as usize;
    if !divisors_are_nonzero(values, count) { return -1; }
    let required = 8 * (count + 1);
    if output.is_null() || capacity < required { return -2; }

    store_i64_le(output, 0, count_value);
    let mut rho = 0i64;
    let mut term = values[1];
    let mut sum = term;
    store_i64_le(output, 8, sum);
    for index in 1..count {
        let top = numerator(values[index + 1], rho);
        let denominator = (1 + MODULUS - top) % MODULUS;
        rho = top * mod_pow(denominator, MODULUS - 2) % MODULUS;
        term = rho * term % MODULUS;
        sum = (sum + term) % MODULUS;
        store_i64_le(output, 8 * (index + 1), sum);
    }
    required as i64
}
