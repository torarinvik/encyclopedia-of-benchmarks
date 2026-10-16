const MAX_N: usize = 256;
const MAX_OUTPUT: usize = 527;
fn write_i64(payload: &mut [u8; MAX_OUTPUT], mut pos: usize, value: i64) -> usize {
    payload[pos..pos + 8].copy_from_slice(&value.to_le_bytes());
    pos += 8;
    pos
}

#[no_mangle]
pub unsafe extern "C" fn min_palindromic_insert(input: *const i64, length: usize,
                                                output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_N + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(1..=MAX_N as i64).contains(&n_value) || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let mut chars = [0_u8; MAX_N];
    for i in 0..n {
        if !(32..=126).contains(&values[i + 1]) { return -1; }
        chars[i] = values[i + 1] as u8;
    }
    let mut dp = [[0_u16; MAX_N]; MAX_N];
    for span in 2..=n {
        for left in 0..=n - span {
            let right = left + span - 1;
            if chars[left] == chars[right] { dp[left][right] = if span > 2 { dp[left + 1][right - 1] } else { 0 }; }
            else { dp[left][right] = dp[left + 1][right].min(dp[left][right - 1]) + 1; }
        }
    }
    let insertions = dp[0][n - 1] as usize;
    let palindrome_length = n + insertions;
    let mut palindrome = [0_u8; 2 * MAX_N - 1];
    let (mut left, mut right) = (0, n - 1);
    let (mut out_left, mut out_right) = (0, palindrome_length - 1);
    while left <= right {
        if chars[left] == chars[right] {
            palindrome[out_left] = chars[left]; palindrome[out_right] = chars[right]; left += 1;
            if right == 0 { break; }
            right -= 1;
        } else if dp[left + 1][right] < dp[left][right - 1] {
            palindrome[out_left] = chars[left]; palindrome[out_right] = chars[left]; left += 1;
        } else {
            palindrome[out_left] = chars[right]; palindrome[out_right] = chars[right];
            if right == 0 { break; }
            right -= 1;
        }
        out_left += 1;
        if out_right == 0 { break; }
        out_right -= 1;
    }
    let mut payload = [0_u8; MAX_OUTPUT];
    let mut written = write_i64(&mut payload, 0, insertions as i64);
    written = write_i64(&mut payload, written, palindrome_length as i64);
    payload[written..written + palindrome_length].copy_from_slice(&palindrome[..palindrome_length]);
    written += palindrome_length;
    if output.is_null() || capacity < written { return -2; }
    std::ptr::copy_nonoverlapping(payload.as_ptr(), output, written);
    written as i64
}
