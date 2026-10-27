const MAX_N: usize = 12;
const MAX_INPUT: usize = 26;
const MAX_Q: usize = 4 * MAX_N * MAX_N;

unsafe fn store(out: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *out.add(offset + b) = (bits >> (8 * b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn knapsack_profit_scaling_fptas(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let cap = *input; let n64 = *input.add(1);
    if cap < 1 || cap > 100 || n64 < 1 || n64 > MAX_N as i64
        || length != 2 + 2 * n64 as usize { return -1; }
    let n = n64 as usize;
    let mut weights = [0i64; MAX_N]; let mut profits = [0i64; MAX_N];
    for i in 0..n {
        weights[i] = *input.add(2 + 2 * i); profits[i] = *input.add(3 + 2 * i);
        if !(1..=100).contains(&weights[i]) || !(1..=10_000).contains(&profits[i]) { return -1; }
    }
    if output.is_null() || capacity < 16 { return -2; }
    let mut order = [0usize; MAX_N]; let mut eligible = 0usize;
    for i in 0..n { if weights[i] <= cap { order[eligible] = i; eligible += 1; } }
    for i in 1..eligible {
        let key = order[i]; let mut j = i;
        while j > 0
            && profits[key] * weights[order[j - 1]] > profits[order[j - 1]] * weights[key] {
            order[j] = order[j - 1]; j -= 1;
        }
        order[j] = key;
    }
    let mut upper = 0i64; let mut room = cap;
    for k in 0..eligible {
        let i = order[k];
        if weights[i] <= room { upper += profits[i]; room -= weights[i]; }
        else { upper += profits[i] * room / weights[i]; break; }
    }
    let mut dp_weight = [cap + 1; MAX_Q + 1]; let mut dp_mask = [0i64; MAX_Q + 1];
    dp_weight[0] = 0; let mut reachable = 0usize;
    if upper > 0 {
        for i in 0..n {
            if weights[i] > cap { continue; }
            let val = (4 * n as i64 * profits[i] / upper) as usize;
            if val == 0 { continue; }
            for q in (0..=reachable).rev() {
                if dp_weight[q] > cap { continue; }
                let next = q + val; let nw = dp_weight[q] + weights[i]; let nm = dp_mask[q] | (1i64 << i);
                if nw < dp_weight[next] || nw == dp_weight[next] && nm < dp_mask[next] {
                    dp_weight[next] = nw; dp_mask[next] = nm;
                }
            }
            reachable += val;
        }
    }
    let mut best = 0usize; for q in 1..=MAX_Q { if dp_weight[q] <= cap { best = q; } }
    let mask = dp_mask[best]; let mut profit = 0i64;
    for i in 0..n { if ((mask as u64 >> i) & 1) != 0 { profit += profits[i]; } }
    store(output, 0, mask); store(output, 8, profit); 16
}
