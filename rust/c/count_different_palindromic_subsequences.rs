const MAX_LENGTH: usize = 20;
const MODULUS: i64 = 1_000_000_007;

fn normalize(value: i64) -> i64 {
    value.rem_euclid(MODULUS)
}

#[no_mangle]
pub unsafe extern "C" fn count_different_palindromic_subsequences(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_LENGTH + 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_LENGTH as i64 || length != values[0] as usize + 1 { return -1; }
    let n = values[0] as usize;
    let mut symbols = [0_usize; MAX_LENGTH];
    for i in 0..n {
        if !(0..=3).contains(&values[i + 1]) { return -1; }
        symbols[i] = values[i + 1] as usize;
    }
    if n == 0 { return 0; }
    let mut next_equal = [n; MAX_LENGTH];
    let mut previous_equal = [usize::MAX; MAX_LENGTH];
    let mut next_at = [n; 4];
    let mut previous_at = [usize::MAX; 4];
    for i in (0..n).rev() {
        next_equal[i] = next_at[symbols[i]];
        next_at[symbols[i]] = i;
    }
    for i in 0..n {
        previous_equal[i] = previous_at[symbols[i]];
        previous_at[symbols[i]] = i;
    }
    let mut dp = [[0_i64; MAX_LENGTH]; MAX_LENGTH];
    for i in 0..n { dp[i][i] = 1; }
    for width in 2..=n {
        for left in 0..=n - width {
            let right = left + width - 1;
            let inner = if width > 2 { dp[left + 1][right - 1] } else { 0 };
            let value;
            if symbols[left] != symbols[right] {
                value = dp[left + 1][right] + dp[left][right - 1] - inner;
            } else {
                let first = next_equal[left];
                let last = previous_equal[right];
                if first >= right || last <= left || first > last {
                    value = 2 * inner + 2;
                } else if first == last {
                    value = 2 * inner + 1;
                } else {
                    let duplicates = if first + 1 <= last - 1 { dp[first + 1][last - 1] } else { 0 };
                    value = 2 * inner - duplicates;
                }
            }
            dp[left][right] = normalize(value);
        }
    }
    dp[0][n - 1]
}
