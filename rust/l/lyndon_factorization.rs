const MAX_SEQUENCE_LENGTH: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn lyndon_factorization(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if length < 1 || length > MAX_SEQUENCE_LENGTH + 1 || input.is_null() { return -1; }
    let n_value = *input;
    if n_value < 0 || n_value > MAX_SEQUENCE_LENGTH as i64 || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    for i in 0..n { let x = *input.add(i + 1); if !(97..=122).contains(&x) { return -1; } }
    let required = 2 * n;
    if capacity < required || (required != 0 && output.is_null()) { return -2; }
    let mut start = 0; let mut out = 0;
    while start < n {
        let mut candidate = start + 1; let mut matched = start;
        while candidate < n && *input.add(matched + 1) <= *input.add(candidate + 1) {
            if *input.add(matched + 1) < *input.add(candidate + 1) { matched = start; } else { matched += 1; }
            candidate += 1;
        }
        let factor_length = candidate - matched;
        while start <= matched {
            for j in 0..factor_length { *output.add(out) = *input.add(start + j + 1) as u8; out += 1; }
            *output.add(out) = 0; out += 1; start += factor_length;
        }
    }
    out as i64
}
