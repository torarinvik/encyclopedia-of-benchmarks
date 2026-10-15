/// Find the rightmost longest ASCII alphanumeric palindrome with substring DP.
const MAX_LENGTH: usize = 1000;

fn is_ascii_alphanumeric(value: i64) -> bool {
    (48..=57).contains(&value) || (65..=90).contains(&value) || (97..=122).contains(&value)
}

#[no_mangle]
pub extern "C" fn longest_palindromic_substring_dp(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH { return -1; }
    for index in 0..length {
        if !is_ascii_alphanumeric(unsafe { *values.add(index) }) { return -1; }
    }

    let mut palindrome = vec![vec![false; length]; length];
    let mut best_start = 0usize;
    let mut best_end = 0usize;
    for gap in 0..length {
        for start_index in 0..(length - gap) {
            let end_index = start_index + gap;
            let is_palindrome = if gap == 0 {
                true
            } else if gap == 1 {
                unsafe { *values.add(start_index) == *values.add(end_index) }
            } else {
                unsafe { *values.add(start_index) == *values.add(end_index) } &&
                    palindrome[start_index + 1][end_index - 1]
            };
            palindrome[start_index][end_index] = is_palindrome;
            if is_palindrome {
                best_start = start_index;
                best_end = end_index;
            }
        }
    }

    let best_length = best_end - best_start + 1;
    if output.is_null() || output_capacity < best_length { return -2; }
    for index in 0..best_length {
        unsafe { *output.add(index) = *values.add(best_start + index) as u8; }
    }
    best_length as i64
}
