const MAX_N: usize = 30;
const MAX_K: usize = 30;
const MAX_INPUT_LENGTH: usize = 33;
const DP_CELLS: usize = MAX_N * MAX_N * (MAX_K + 1);
const INFINITY: i64 = 1i64 << 60;

#[inline]
fn dp_index(left: usize, right: usize, piles: usize) -> usize {
    (left * MAX_N + right) * (MAX_K + 1) + piles
}

#[no_mangle]
pub unsafe extern "C" fn minimum_cost_to_merge_stones(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_N as i64).contains(&values[0]) || !(2..=MAX_K as i64).contains(&values[1]) {
        return -1;
    }
    let n = values[0] as usize;
    let merge_count = values[1] as usize;
    if length != n + 2 || values[2..].iter().any(|&stone| !(1..=100).contains(&stone)) {
        return -1;
    }

    let mut prefix = [0i64; MAX_N + 1];
    for i in 0..n {
        prefix[i + 1] = prefix[i] + values[i + 2];
    }
    if (n - 1) % (merge_count - 1) != 0 {
        return -1;
    }

    let mut dp = [INFINITY; DP_CELLS];
    for i in 0..n {
        dp[dp_index(i, i, 1)] = 0;
    }
    for interval_length in 2..=n {
        for left in 0..=n - interval_length {
            let right = left + interval_length - 1;
            let maximum_piles = merge_count.min(interval_length);
            for piles in 2..=maximum_piles {
                let mut best = INFINITY;
                for cut in left..right {
                    let first = dp[dp_index(left, cut, 1)];
                    let rest = dp[dp_index(cut + 1, right, piles - 1)];
                    if first < INFINITY && rest < INFINITY {
                        best = best.min(first + rest);
                    }
                }
                dp[dp_index(left, right, piles)] = best;
            }
            if interval_length >= merge_count {
                let to_k = dp[dp_index(left, right, merge_count)];
                if to_k < INFINITY {
                    dp[dp_index(left, right, 1)] = to_k + prefix[right + 1] - prefix[left];
                }
            }
        }
    }
    let answer = dp[dp_index(0, n - 1, 1)];
    if answer >= INFINITY { -1 } else { answer }
}
