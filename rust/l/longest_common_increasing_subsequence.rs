#[no_mangle]
pub unsafe extern "C" fn longest_common_increasing_subsequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=67).contains(&length) {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let n = input[0];
    let m = input[1];
    if !(0..=32).contains(&n) || !(0..=32).contains(&m)
        || length != 2 + n as usize + m as usize
    {
        return -1;
    }
    let n = n as usize;
    let m = m as usize;
    if input[2..].iter().any(|&value| !(-16..=16).contains(&value)) {
        return -1;
    }

    let mut ending_at = [0i64; 32];
    for i in 0..n {
        let value = input[2 + i];
        let mut best_smaller = 0i64;
        for j in 0..m {
            let other = input[2 + n + j];
            if value > other {
                best_smaller = best_smaller.max(ending_at[j]);
            } else if value == other {
                ending_at[j] = ending_at[j].max(best_smaller + 1);
            }
        }
    }
    ending_at[..m].iter().copied().max().unwrap_or(0)
}
