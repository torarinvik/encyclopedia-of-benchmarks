const MAX_BITS: usize = 64;
const MAX_PARSEABLE: usize = 131;
const MAX_OUTPUT: usize = 66;

fn canonical(bits: &[i64]) -> bool {
    if bits.len() == 1 && bits[0] == 0 { return true; }
    if bits.is_empty() || bits[0] != 1 { return false; }
    for i in 0..bits.len() {
        if bits[i] != 0 && bits[i] != 1 { return false; }
        if i + 1 < bits.len() && bits[i] == 1 && bits[i + 1] == 1 { return false; }
    }
    true
}

fn stage_one(d: &mut [u8; MAX_OUTPUT], n: usize) {
    for i in 0..n.saturating_sub(3) {
        if d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 0 {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; d[i + 3] += 1;
        } else if d[i] == 0 && d[i + 1] == 3 && d[i + 2] == 0 {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; d[i + 3] += 1;
        } else if d[i] == 0 && d[i + 1] == 2 && d[i + 2] == 1 {
            d[i] = 1; d[i + 1] = 1; d[i + 2] = 0;
        } else if d[i] == 0 && d[i + 1] == 1 && d[i + 2] == 2 {
            d[i] = 1; d[i + 1] = 0; d[i + 2] = 1;
        }
    }
    if n >= 3 && d[n - 3] == 0 && d[n - 2] == 3 && d[n - 1] == 0 {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1;
    } else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 0 {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    } else if n >= 4 && d[n - 4] == 0 && d[n - 3] == 1 && d[n - 2] == 2 && d[n - 1] == 0 {
        d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0;
    } else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 2 && d[n - 1] == 1 {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0;
    }
    if n >= 2 && d[n - 2] == 0 && d[n - 1] == 3 {
        d[n - 2] = 1; d[n - 1] = 1;
    } else if n >= 2 && d[n - 2] == 0 && d[n - 1] == 2 {
        d[n - 2] = 1; d[n - 1] = 0;
    } else if n >= 3 && d[n - 3] == 0 && d[n - 2] == 1 && d[n - 1] == 2 {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn zeckendorf_addition(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_PARSEABLE { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let first_n_i64 = values[0];
    if first_n_i64 < 1 || first_n_i64 > MAX_BITS as i64 { return -1; }
    let first_n = first_n_i64 as usize;
    let second_n_index = first_n + 1;
    if second_n_index >= length { return -1; }
    let second_n_i64 = values[second_n_index];
    if second_n_i64 < 1 || second_n_i64 > MAX_BITS as i64 { return -1; }
    let second_n = second_n_i64 as usize;
    if length != second_n_index + second_n + 1 { return -1; }
    let first = &values[1..second_n_index];
    let second = &values[second_n_index + 1..];
    if !canonical(first) || !canonical(second) { return -1; }

    let width = first_n.max(second_n);
    let first_offset = width - first_n;
    let second_offset = width - second_n;
    let mut digits = [0u8; MAX_OUTPUT];
    let mut digit_count = width + 1;
    for i in 0..width {
        let a = if i < first_offset { 0 } else { first[i - first_offset] as u8 };
        let b = if i < second_offset { 0 } else { second[i - second_offset] as u8 };
        digits[i + 1] = a + b;
    }
    stage_one(&mut digits, digit_count);
    for i in (0..digit_count).rev() { digits[i + 1] = digits[i]; }
    digits[0] = 0;
    digit_count += 1;
    for i in (0..=digit_count - 3).rev() {
        if digits[i] == 0 && digits[i + 1] == 1 && digits[i + 2] == 1 {
            digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0;
        }
    }
    for i in 0..digit_count - 2 {
        if digits[i] == 0 && digits[i + 1] == 1 && digits[i + 2] == 1 {
            digits[i] = 1; digits[i + 1] = 0; digits[i + 2] = 0;
        }
    }
    let mut first_output = 0;
    while first_output + 1 < digit_count && digits[first_output] == 0 { first_output += 1; }
    let required = digit_count - first_output;
    if output.is_null() || output_capacity < required { return -2; }
    let destination = std::slice::from_raw_parts_mut(output, required);
    for i in 0..required { destination[i] = b'0' + digits[first_output + i]; }
    required as i64
}
