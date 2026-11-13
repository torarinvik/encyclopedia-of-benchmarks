/// Bounded knapsack by residue-class sliding maxima.
#[no_mangle]
pub extern "C" fn bounded_knapsack_monotone_queue(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || !(2..=51).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(packed, length) };
    if !(0..=64).contains(&input[0]) || !(0..=16).contains(&input[1]) { return -1; }
    let capacity = input[0] as usize;
    let types = input[1] as usize;
    if length != 2 + 3 * types { return -1; }
    for item in 0..types {
        let weight = input[2 + 3 * item];
        let value = input[3 + 3 * item];
        let count = input[4 + 3 * item];
        if !(1..=16).contains(&weight) || !(0..=100).contains(&value) || !(0..=16).contains(&count) { return -1; }
    }

    let mut dp = [0_i64; 65];
    let mut next = [0_i64; 65];
    let mut queue_score = [0_i64; 65];
    let mut queue_index = [0_usize; 65];
    for item in 0..types {
        let weight = input[2 + 3 * item] as usize;
        let value = input[3 + 3 * item];
        let count = input[4 + 3 * item] as usize;
        for residue in 0..weight.min(capacity + 1) {
            let (mut head, mut tail) = (0_usize, 0_usize);
            let max_t = (capacity - residue) / weight;
            for t in 0..=max_t {
                let current = residue + t * weight;
                let score = dp[current] - t as i64 * value;
                while tail > head && queue_score[tail - 1] <= score { tail -= 1; }
                queue_index[tail] = t;
                queue_score[tail] = score;
                tail += 1;
                let first_allowed = t.saturating_sub(count);
                while head < tail && queue_index[head] < first_allowed { head += 1; }
                next[current] = t as i64 * value + queue_score[head];
            }
        }
        for c in 0..=capacity { dp[c] = next[c]; }
    }
    dp[capacity]
}
