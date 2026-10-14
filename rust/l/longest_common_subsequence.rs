/// Return the LCS length of two packed ASCII sequences.
#[no_mangle]
pub extern "C" fn longest_common_subsequence(packed: *const i64, length: usize) -> i64 {
    if length < 2 || length > 512 || packed.is_null() {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let left_length = packed[0];
    let right_length = packed[1];
    if !(0..=255).contains(&left_length)
        || !(0..=255).contains(&right_length)
        || length != 2 + left_length as usize + right_length as usize
    {
        return -1;
    }
    let left = &packed[2..2 + left_length as usize];
    let right = &packed[2 + left_length as usize..];
    if left.iter().chain(right.iter()).any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let mut dp = [0i64; 256];
    for &left_value in left {
        let mut diagonal = 0i64;
        for right_index in 1..=right_length as usize {
            let above = dp[right_index];
            if left_value == right[right_index - 1] {
                dp[right_index] = diagonal + 1;
            } else if dp[right_index - 1] > dp[right_index] {
                dp[right_index] = dp[right_index - 1];
            }
            diagonal = above;
        }
    }
    dp[right_length as usize]
}
