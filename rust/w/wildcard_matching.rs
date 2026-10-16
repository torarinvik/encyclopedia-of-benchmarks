/// Full-string wildcard matching for lowercase ASCII text.
#[no_mangle]
pub extern "C" fn wildcard_matching(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=35).contains(&length) {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=12).contains(&input[0]) || !(0..=20).contains(&input[1]) {
        return -1;
    }
    let text_length = input[0] as usize;
    let pattern_length = input[1] as usize;
    if length != 2 + text_length + pattern_length {
        return -1;
    }
    if input[2..2 + text_length].iter().any(|&code| !(97..=122).contains(&code)) {
        return -1;
    }
    let pattern_start = 2 + text_length;
    if input[pattern_start..].iter().any(|&token| {
        !((97..=122).contains(&token) || token == 42 || token == 63)
    }) {
        return -1;
    }

    let mut dp = [[false; 21]; 13];
    dp[0][0] = true;
    for column in 1..=pattern_length {
        if input[pattern_start + column - 1] == 42 {
            dp[0][column] = dp[0][column - 1];
        }
    }
    for row in 1..=text_length {
        for column in 1..=pattern_length {
            let token = input[pattern_start + column - 1];
            if token == input[1 + row] || token == 63 {
                dp[row][column] = dp[row - 1][column - 1];
            } else if token == 42 {
                dp[row][column] = dp[row - 1][column] || dp[row][column - 1];
            }
        }
    }
    i64::from(dp[text_length][pattern_length])
}
