/// Bottom-up count of ordered denomination sequences.
#[no_mangle]
pub extern "C" fn combination_sum_iv(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || !(2..=18).contains(&length) {
        return i64::MIN;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    if !(0..=16).contains(&packed[0]) || !(0..=63).contains(&packed[1]) {
        return i64::MIN;
    }
    let count = packed[0] as usize;
    let target = packed[1] as usize;
    if length != count + 2 {
        return i64::MIN;
    }
    for i in 0..count {
        if !(1..=63).contains(&packed[i + 2]) {
            return i64::MIN;
        }
        for j in 0..i {
            if packed[i + 2] == packed[j + 2] {
                return i64::MIN;
            }
        }
    }

    let mut dp = [0_i64; 64];
    dp[0] = 1;
    for sum in 1..=target {
        for i in 0..count {
            let denomination = packed[i + 2] as usize;
            if denomination <= sum {
                dp[sum] += dp[sum - denomination];
            }
        }
    }
    dp[target]
}
