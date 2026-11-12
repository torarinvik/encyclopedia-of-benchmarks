const MAX_N: usize = 8;
const MAX_K: usize = 16;
const MAX_DIAGONALS: usize = 2 * MAX_N;

fn diagonal_size(index: usize) -> usize {
    if index & 1 != 0 { (index / 4) * 2 + 1 } else { ((index - 1) / 4) * 2 + 2 }
}

fn color_counts(k: usize, last_diagonal: usize) -> [i64; MAX_K + 1] {
    let mut dp = [[0i64; MAX_K + 1]; MAX_DIAGONALS];
    dp[0][0] = 1;
    dp[1][0] = 1;
    if k >= 1 { dp[1][1] = 1; }
    for diagonal in 2..=last_diagonal {
        dp[diagonal][0] = 1;
        let squares = diagonal_size(diagonal) as i64;
        for placed in 1..=k {
            dp[diagonal][placed] = dp[diagonal - 2][placed] +
                dp[diagonal - 2][placed - 1] * (squares - placed as i64 + 1);
        }
    }
    let mut counts = [0i64; MAX_K + 1];
    counts[..=k].copy_from_slice(&dp[last_diagonal][..=k]);
    counts
}

fn solve(input: &[i64]) -> i64 {
    if input.len() != 2 { return -1; }
    if !(1..=MAX_N as i64).contains(&input[0]) || !(0..=MAX_K as i64).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let k = input[1] as usize;
    if k > (if n == 1 { 1 } else { 2 * n - 2 }) { return 0; }
    let black = color_counts(k, 2 * n - 1);
    let white = color_counts(k, 2 * n - 2);
    (0..=k).map(|left| black[left] * white[k - left]).sum()
}

#[no_mangle]
pub unsafe extern "C" fn bishop_placements_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
