/// Find the leftmost longest ASCII alphanumeric palindrome by expanding centers.
fn is_ascii_alphanumeric(value: i64) -> bool {
    (48..=57).contains(&value) || (65..=90).contains(&value) || (97..=122).contains(&value)
}

#[no_mangle]
pub extern "C" fn longest_palindromic_substring(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length == 0 || length > 1000 || values.is_null() { return -1; }
    for index in 0..length {
        if !is_ascii_alphanumeric(unsafe { *values.add(index) }) { return -1; }
    }

    let mut best_start = 0usize;
    let mut best_length = 1usize;
    for center in 0..length {
        let mut left = center;
        let mut right = center;
        while left > 0 && right + 1 < length &&
            unsafe { *values.add(left - 1) == *values.add(right + 1) } {
            left -= 1;
            right += 1;
        }
        let mut candidate_length = right - left + 1;
        if candidate_length > best_length {
            best_start = left;
            best_length = candidate_length;
        }

        left = center;
        right = center + 1;
        while right < length && unsafe { *values.add(left) == *values.add(right) } {
            candidate_length = right - left + 1;
            if candidate_length > best_length {
                best_start = left;
                best_length = candidate_length;
            }
            if left == 0 || right + 1 == length { break; }
            left -= 1;
            right += 1;
        }
    }

    if output_capacity < best_length || output.is_null() { return -2; }
    for index in 0..best_length {
        unsafe { *output.add(index) = *values.add(best_start + index) as u8; }
    }
    best_length as i64
}
