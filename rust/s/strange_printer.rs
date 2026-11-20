const MAX_LENGTH: usize = 8;
const MAX_PARSEABLE_LENGTH: usize = MAX_LENGTH + 2;
const TABLE_SIDE: usize = MAX_LENGTH + 1;

fn solve(input: &[i64]) -> i64 {
    if input.len() < 1 || input.len() > MAX_PARSEABLE_LENGTH { return -1; }
    let n_raw = input[0];
    if n_raw < 0 || n_raw > MAX_LENGTH as i64 { return -1; }
    let n = n_raw as usize;
    if input.len() != n + 1 || input[1..].iter().any(|&symbol| !(0..=2).contains(&symbol)) {
        return -1;
    }
    if n == 0 { return 0; }

    let mut dp = [0_i64; TABLE_SIDE * TABLE_SIDE];
    for left in (0..n).rev() {
        dp[left * TABLE_SIDE + left] = 1;
        for right in left + 1..n {
            let mut best = dp[(left + 1) * TABLE_SIDE + right] + 1;
            for merge in left + 1..=right {
                if input[left + 1] != input[merge + 1] { continue; }
                let middle = if merge == left + 1 {
                    0
                } else {
                    dp[(left + 1) * TABLE_SIDE + merge - 1]
                };
                best = best.min(middle + dp[merge * TABLE_SIDE + right]);
            }
            dp[left * TABLE_SIDE + right] = best;
        }
    }
    dp[n - 1]
}

#[no_mangle]
pub unsafe extern "C" fn strange_printer(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_PARSEABLE_LENGTH { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
