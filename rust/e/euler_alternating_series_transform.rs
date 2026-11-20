const MAX_TERMS: usize = 16;
const MAX_WORDS: usize = 18;
const VALUE_LIMIT: i64 = 1_000_000;
const OUTPUT_BYTES: usize = 16;

fn euler_gcd(mut left: u64, mut right: u64) -> u64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn euler_store_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn euler_alternating_series_transform(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_WORDS { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let n_value = values[0];
    if n_value < 1 || n_value > MAX_TERMS as i64 || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    for value in &values[1..=n] {
        if *value < -VALUE_LIMIT || *value > VALUE_LIMIT { return -1; }
    }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    let mut numerator = 0_i64;
    for order in 0..n {
        let mut difference = 0_i64;
        let mut coefficient = 1_i64;
        for index in 0..=order {
            let term = values[order - index + 1];
            if index % 2 == 0 { difference += coefficient * term; }
            else { difference -= coefficient * term; }
            if index < order {
                coefficient = coefficient * (order - index) as i64 / (index + 1) as i64;
            }
        }
        let weight = 1_i64 << (n - order - 1);
        let weighted = difference * weight;
        if order % 2 == 0 { numerator += weighted; }
        else { numerator -= weighted; }
    }

    let mut denominator = 1_i64 << n;
    let divisor = euler_gcd(numerator.unsigned_abs(), denominator as u64);
    numerator /= divisor as i64;
    denominator /= divisor as i64;
    euler_store_i64(output, 0, numerator);
    euler_store_i64(output, 8, denominator);
    OUTPUT_BYTES as i64
}
