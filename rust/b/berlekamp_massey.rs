const MODULUS: i64 = 998_244_353;
const MAX_ORDER: usize = 8;
const MAX_TERMS: usize = 2 * MAX_ORDER;
const MAX_INPUT_VALUES: usize = 1 + MAX_TERMS + 1;

fn normalize(value: i64) -> i64 {
    let remainder = value % MODULUS;
    if remainder < 0 { remainder + MODULUS } else { remainder }
}

fn multiply(left: i64, right: i64) -> i64 {
    (left * right) % MODULUS
}

fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent > 0 {
        if exponent & 1 != 0 { result = multiply(result, base); }
        base = multiply(base, base);
        exponent >>= 1;
    }
    result
}

unsafe fn store_i64_le(output: *mut u8, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
}

fn infer_recurrence(sequence: &[i64; MAX_TERMS], term_count: usize,
                    coefficients: &mut [i64; MAX_TERMS + 1]) -> usize {
    let mut current = [0i64; MAX_TERMS + 1];
    let mut previous = [0i64; MAX_TERMS + 1];
    let mut old = [0i64; MAX_TERMS + 1];
    let mut current_length = 0usize;
    let mut previous_length = 0usize;
    let mut last_index: isize = -1;
    let mut last_discrepancy = 0i64;

    for index in 0..term_count {
        let mut predicted = 0;
        for lag in 0..current_length.min(index) {
            predicted = normalize(predicted + multiply(sequence[index - lag - 1], current[lag]));
        }
        let discrepancy = normalize(sequence[index] - predicted);
        if discrepancy == 0 { continue; }

        if last_index < 0 {
            last_index = index as isize;
            last_discrepancy = discrepancy;
            current_length = index + 1;
            for lag in 0..current_length { current[lag] = 0; }
            continue;
        }

        old[..current_length].copy_from_slice(&current[..current_length]);
        let old_length = current_length;
        let shift = index as isize - last_index;
        let scale = multiply(discrepancy, power(last_discrepancy, MODULUS - 2));
        let needed_length = previous_length + shift as usize;
        if current_length < needed_length {
            current[current_length..needed_length].fill(0);
            current_length = needed_length;
        }
        current[shift as usize - 1] = normalize(current[shift as usize - 1] + scale);
        for lag in 0..previous_length {
            let target = shift as usize + lag;
            current[target] = normalize(current[target] - multiply(scale, previous[lag]));
        }

        if (old_length as isize - index as isize)
            < (previous_length as isize - last_index)
        {
            previous[..old_length].copy_from_slice(&old[..old_length]);
            previous_length = old_length;
            last_index = index as isize;
            last_discrepancy = discrepancy;
        }
    }

    coefficients[..current_length].copy_from_slice(&current[..current_length]);
    current_length
}

#[no_mangle]
pub unsafe extern "C" fn berlekamp_massey(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES { return -1; }
    let bound_value = *input;
    if !(1..=MAX_ORDER as i64).contains(&bound_value) { return -1; }
    let bound = bound_value as usize;
    let term_count = 2 * bound;
    if length != 1 + term_count { return -1; }

    let mut sequence = [0i64; MAX_TERMS];
    for index in 0..term_count {
        let value = *input.add(1 + index);
        if !(0..MODULUS).contains(&value) { return -1; }
        sequence[index] = value;
    }

    let mut coefficients = [0i64; MAX_TERMS + 1];
    let order = infer_recurrence(&sequence, term_count, &mut coefficients);
    if order > bound { return -1; }
    let output_bytes = 8 * (order + 1);
    if output.is_null() || capacity < output_bytes { return -2; }
    store_i64_le(output, order as i64);
    for lag in 0..order { store_i64_le(output.add(8 * (lag + 1)), coefficients[lag]); }
    output_bytes as i64
}
