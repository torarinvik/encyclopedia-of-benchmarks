const MAX_N: usize = 8;
const MAX_M: usize = 56;
const MAX_LENGTH: usize = 114;
const MAX_STATES: usize = 256;
const INF: i64 = i64::MAX / 4;

#[no_mangle]
pub unsafe extern "C" fn minimum_directed_feedback_arc_set(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LENGTH + 1 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 1 || words[0] > MAX_N as i64 || words[1] < 0 || words[1] > MAX_M as i64 {
        return -1;
    }
    let n = words[0] as usize;
    let m = words[1] as usize;
    if length != 2 + 2 * m { return -1; }

    let mut outgoing = [0_usize; MAX_N];
    for edge in 0..m {
        let tail_value = words[2 + 2 * edge];
        let head_value = words[3 + 2 * edge];
        if tail_value < 0 || head_value < 0 || tail_value >= n as i64 ||
            head_value >= n as i64 || tail_value == head_value { return -1; }
        let tail = tail_value as usize;
        let head = head_value as usize;
        let bit = 1_usize << head;
        if outgoing[tail] & bit != 0 { return -1; }
        outgoing[tail] |= bit;
    }

    let full = (1_usize << n) - 1;
    let mut dp = [INF; MAX_STATES];
    dp[0] = 0;
    for prefix in 0..=full {
        if dp[prefix] == INF { continue; }
        for vertex in 0..n {
            let bit = 1_usize << vertex;
            if prefix & bit != 0 { continue; }
            let backward = (outgoing[vertex] & prefix).count_ones() as i64;
            let target = prefix | bit;
            let candidate = dp[prefix] + backward;
            if candidate < dp[target] { dp[target] = candidate; }
        }
    }
    dp[full]
}
