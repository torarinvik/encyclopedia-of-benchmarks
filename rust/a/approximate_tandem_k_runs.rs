const MAX_TEXT: usize = 24;
const MAX_INPUT: usize = 26;
const MAX_OUTPUT: usize = 34504;

fn max_window_mismatches(input: &[i64], start: usize, factor_length: usize, period: usize) -> usize {
    let windows = factor_length - 2 * period + 1;
    let mut maximum = 0;
    for window in 0..windows {
        let mut count = 0;
        for offset in 0..period {
            count += (input[2 + start + window + offset] != input[2 + start + window + period + offset]) as usize;
        }
        if count > maximum { maximum = count; }
    }
    maximum
}
fn count_records(input: &[i64], n: usize, budget: usize) -> usize {
    let mut count = 0;
    for start in 0..n {
        let remaining = n - start;
        for period in 1..=((remaining.saturating_sub(1)) / 2) {
            for factor_length in (2 * period + 1)..=remaining {
                count += (max_window_mismatches(input, start, factor_length, period) <= budget) as usize;
            }
        }
    }
    count
}
unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn approximate_tandem_k_runs(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let n0 = words[0];
    let budget0 = words[1];
    if n0 < 3 || n0 > MAX_TEXT as i64 || budget0 < 0 || budget0 > 8 || length != n0 as usize + 2 { return -1; }
    let n = n0 as usize;
    let budget = budget0 as usize;
    if words[2..].iter().any(|&symbol| !(0..=3).contains(&symbol)) { return -1; }
    let count = count_records(words, n, budget);
    let bytes = 8 * (1 + 4 * count);
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    store_i64_le(output, 0, count as i64);
    let mut record = 0usize;
    for start in 0..n {
        let remaining = n - start;
        for period in 1..=((remaining.saturating_sub(1)) / 2) {
            for factor_length in (2 * period + 1)..=remaining {
                let errors = max_window_mismatches(words, start, factor_length, period);
                if errors <= budget {
                    let offset = 8 * (1 + 4 * record);
                    store_i64_le(output, offset, start as i64);
                    store_i64_le(output, offset + 8, factor_length as i64);
                    store_i64_le(output, offset + 16, period as i64);
                    store_i64_le(output, offset + 24, errors as i64);
                    record += 1;
                }
            }
        }
    }
    bytes as i64
}
