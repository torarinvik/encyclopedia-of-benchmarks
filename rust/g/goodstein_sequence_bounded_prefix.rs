fn small_power(base: i64, exponent: i64) -> i64 {
    let mut result = 1_i64;
    for _ in 0..exponent {
        result *= base;
    }
    result
}

fn rebase_hereditary(value: i64, base: i64, raised_base: i64) -> i64 {
    if value == 0 {
        return 0;
    }
    let mut result = 0_i64;
    let mut place = 1_i64;
    let mut exponent = 0_i64;
    while place <= value {
        let digit = (value / place) % base;
        if digit != 0 {
            let raised_exponent = rebase_hereditary(exponent, base, raised_base);
            result += digit * small_power(raised_base, raised_exponent);
        }
        place *= base;
        exponent += 1;
    }
    result
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn goodstein_sequence_bounded_prefix(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || !(1..=3).contains(&length) || length != 2 {
        return -1;
    }
    let input = std::slice::from_raw_parts(raw, length);
    let start = input[0];
    let transitions = input[1];
    if !(0..=4).contains(&start) || !(0..=16).contains(&transitions) {
        return -1;
    }

    let mut terms = [0_i64; 17];
    let mut count = 1_usize;
    terms[0] = start;
    let mut current = start;
    let mut base = 2_i64;
    for _ in 0..transitions {
        if current == 0 {
            break;
        }
        current = rebase_hereditary(current, base, base + 1) - 1;
        base += 1;
        terms[count] = current;
        count += 1;
    }

    let output_bytes = (count + 1) * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let destination = std::slice::from_raw_parts_mut(output, output_bytes);
    store_i64_le(destination, 0, count as i64);
    for index in 0..count {
        store_i64_le(destination, (index + 1) * 8, terms[index]);
    }
    output_bytes as i64
}
