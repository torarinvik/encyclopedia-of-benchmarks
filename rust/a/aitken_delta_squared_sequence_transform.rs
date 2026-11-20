const MAX_TERMS: usize = 64;
const MAX_WORDS: usize = 66;
const VALUE_LIMIT: i64 = 1_000_000;

fn aitken_gcd(mut left: u64, mut right: u64) -> u64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn aitken_store_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn aitken_delta_squared_sequence_transform(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 3 || length > MAX_WORDS { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let n_value = values[0];
    if n_value < 2 || n_value > MAX_TERMS as i64 || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    for value in &values[1..=n] {
        if *value < -VALUE_LIMIT || *value > VALUE_LIMIT { return -1; }
    }
    let output_length = 16 * (n - 2);
    if output.is_null() || output_capacity < output_length { return -2; }

    for index in 0..n - 2 {
        let first = values[index + 1];
        let middle = values[index + 2];
        let last = values[index + 3];
        let mut numerator = first * last - middle * middle;
        let mut denominator = first - 2 * middle + last;
        if denominator == 0 {
            if first == middle && middle == last {
                numerator = first;
                denominator = 1;
            } else {
                numerator = 0;
            }
        } else {
            if denominator < 0 { numerator = -numerator; denominator = -denominator; }
            let divisor = aitken_gcd(numerator.unsigned_abs(), denominator as u64);
            numerator /= divisor as i64;
            denominator /= divisor as i64;
        }
        aitken_store_i64(output, index * 16, numerator);
        aitken_store_i64(output, index * 16 + 8, denominator);
    }
    output_length as i64
}
