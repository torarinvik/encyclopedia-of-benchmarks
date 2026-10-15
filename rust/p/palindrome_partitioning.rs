const MAX_LENGTH: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn palindrome_partitioning(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > MAX_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }
    if output.is_null() || output_capacity < 8 {
        return -2;
    }

    let mut palindrome = [[false; MAX_LENGTH]; MAX_LENGTH];
    let mut cuts = [0_i64; MAX_LENGTH];
    for end in 0..length {
        let mut best = end as i64;
        for start in 0..=end {
            if values[start] == values[end]
                && (end - start < 2 || palindrome[start + 1][end - 1])
            {
                palindrome[start][end] = true;
                let candidate = if start == 0 { 0 } else { cuts[start - 1] + 1 };
                best = best.min(candidate);
            }
        }
        cuts[end] = best;
    }

    let bytes = cuts[length - 1].to_le_bytes();
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, 8);
    1
}
