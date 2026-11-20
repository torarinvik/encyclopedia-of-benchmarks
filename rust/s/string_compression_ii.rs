const MAX_N: usize = 12;
const MAX_INPUT: usize = 15;
const WIDTH: usize = MAX_N + 1;
const INF: i64 = 1000;

fn run_cost(kept: usize) -> i64 {
    if kept == 1 { return 1; }
    let mut value = kept;
    let mut digits = 0;
    while value > 0 { digits += 1; value /= 10; }
    1 + digits
}

fn solve(input: &[i64]) -> i64 {
    if input.len() < 2 || input.len() > MAX_INPUT { return -1; }
    let raw_n = input[0];
    let raw_k = input[1];
    if raw_n < 0 || raw_n > MAX_N as i64 || raw_k < 0 || raw_k > raw_n { return -1; }
    let n = raw_n as usize;
    let budget = raw_k as usize;
    if input.len() != n + 2 || input[2..].iter().any(|&symbol| !(0..=25).contains(&symbol)) {
        return -1;
    }

    let mut dp = [[INF; WIDTH]; WIDTH];
    dp[0][0] = 0;
    for start in 0..n {
        for used in 0..=budget {
            let prefix_cost = dp[start][used];
            if prefix_cost == INF { continue; }
            if used < budget {
                dp[start + 1][used + 1] = dp[start + 1][used + 1].min(prefix_cost);
            }
            let mut same = 0;
            for end in start..n {
                if input[end + 2] == input[start + 2] { same += 1; }
                let span = end - start + 1;
                for kept in 1..=same {
                    let deleted = used + span - kept;
                    if deleted > budget { continue; }
                    let candidate = prefix_cost + run_cost(kept);
                    dp[end + 1][deleted] = dp[end + 1][deleted].min(candidate);
                }
            }
        }
    }
    *dp[n][..=budget].iter().min().unwrap_or(&0)
}

#[no_mangle]
pub unsafe extern "C" fn string_compression_ii(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT).contains(&length) { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
