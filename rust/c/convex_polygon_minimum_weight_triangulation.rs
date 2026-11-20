#[no_mangle]
pub unsafe extern "C" fn convex_polygon_minimum_weight_triangulation(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(1..=37).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(3..=10).contains(&values[0]) {
        return -1;
    }
    let n = values[0] as usize;
    let mut diagonal_count = 0usize;
    for i in 0..n {
        for j in (i + 2)..n {
            if !(i == 0 && j == n - 1) {
                diagonal_count += 1;
            }
        }
    }
    if length != 1 + diagonal_count {
        return -1;
    }

    let mut weight = [[0_i64; 10]; 10];
    let mut at = 1usize;
    for i in 0..n {
        for j in (i + 2)..n {
            if i == 0 && j == n - 1 {
                continue;
            }
            let value = values[at];
            if !(0..=1000).contains(&value) {
                return -1;
            }
            weight[i][j] = value;
            at += 1;
        }
    }

    let mut dp = [[0_i64; 10]; 10];
    for span in 2..n {
        for left in 0..(n - span) {
            let right = left + span;
            let mut best = 7001_i64;
            for split in (left + 1)..right {
                let left_edge = if split - left == 1 { 0 } else { weight[left][split] };
                let right_edge = if right - split == 1 { 0 } else { weight[split][right] };
                let candidate = dp[left][split] + dp[split][right] + left_edge + right_edge;
                if candidate < best {
                    best = candidate;
                }
            }
            dp[left][right] = best;
        }
    }
    dp[0][n - 1]
}
