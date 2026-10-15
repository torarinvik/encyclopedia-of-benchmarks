/// Check whether the packed values match the generated Golomb prefix.
const MAX_N: usize = 1024;

#[no_mangle]
pub extern "C" fn golomb_sequence_validator(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_N {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > MAX_N as i64 {
        return -1;
    }
    let n = input[0] as usize;
    if length != n {
        return -1;
    }
    if input[1..].iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) {
        return -1;
    }

    let mut dp = [0_i64; MAX_N];
    dp[0] = 1;
    for i in 1..n {
        let previous = dp[i - 1] as usize;
        let nested = dp[previous] as usize;
        let source = i - nested;
        dp[i] = 1 + dp[source];
    }
    for index in 1..n {
        if input[index] != dp[index] {
            return 0;
        }
    }
    1
}
