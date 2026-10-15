/// Return shortest common supersequence length for two packed ASCII sequences.
#[no_mangle]
pub extern "C" fn shortest_common_supersequence_length(packed: *const i64, length: usize) -> i64 {
    if length < 2 || length > 512 || packed.is_null() {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    let m = packed[0];
    let n = packed[1];
    if !(0..=255).contains(&m) || !(0..=255).contains(&n)
        || length != 2 + m as usize + n as usize
    {
        return -1;
    }
    let left = &packed[2..2 + m as usize];
    let right = &packed[2 + m as usize..];
    if left.iter().chain(right.iter()).any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let columns = n as usize + 1;
    let mut dp = [0i64; 256 * 256];
    for i in 1..=m as usize {
        for j in 1..=n as usize {
            let cell = i * columns + j;
            if left[i - 1] == right[j - 1] {
                dp[cell] = dp[(i - 1) * columns + j - 1] + 1;
            } else {
                dp[cell] = dp[(i - 1) * columns + j].max(dp[i * columns + j - 1]);
            }
        }
    }
    m + n - dp[m as usize * columns + n as usize]
}
