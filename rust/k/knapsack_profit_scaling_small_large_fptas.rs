const MAX_N: usize = 8;
const MAX_INPUT: usize = 18;
const MAX_Q: usize = 128;

unsafe fn store(out: *mut u8, off: usize, value: i64) {
    let bits = value as u64;
    for b in 0..8 { *out.add(off + b) = (bits >> (8 * b)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn knapsack_profit_scaling_small_large_fptas(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let cap = *input; let n64 = *input.add(1);
    if cap < 1 || cap > 30 || n64 < 1 || n64 > MAX_N as i64 || length != 2 + 2 * n64 as usize { return -1; }
    let n = n64 as usize;
    let mut w = [0i64; MAX_N]; let mut p = [0i64; MAX_N];
    for i in 0..n { w[i] = *input.add(2 + 2*i); p[i] = *input.add(3 + 2*i); if !(1..=30).contains(&w[i]) || !(1..=100).contains(&p[i]) { return -1; } }
    if output.is_null() || capacity < 16 { return -2; }
    let mut order = [0usize; MAX_N]; let mut eligible = 0;
    for i in 0..n { if w[i] <= cap { order[eligible] = i; eligible += 1; } }
    for i in 1..eligible { let key = order[i]; let mut j = i; while j > 0 && p[key]*w[order[j-1]] > p[order[j-1]]*w[key] { order[j] = order[j-1]; j -= 1; } order[j] = key; }
    let mut upper_num = 0i64; let mut upper_den = 1i64; let mut room = cap;
    for k in 0..eligible { let i = order[k]; if w[i] <= room { upper_num += p[i]; room -= w[i]; } else { upper_num = upper_num*w[i] + p[i]*room; upper_den = w[i]; break; } }
    let mut small = [0usize; MAX_N]; let mut large = [0usize; MAX_N]; let mut ns = 0; let mut nl = 0;
    for i in 0..n { if w[i] <= cap { if 4*p[i]*upper_den <= upper_num { small[ns] = i; ns += 1; } else { large[nl] = i; nl += 1; } } }
    for i in 1..ns { let key = small[i]; let mut j = i; while j > 0 && p[key]*w[small[j-1]] > p[small[j-1]]*w[key] { small[j] = small[j-1]; j -= 1; } small[j] = key; }
    let mut dpw = [cap + 1; MAX_Q + 1]; let mut dpm = [0i64; MAX_Q + 1]; dpw[0] = 0; let mut reachable = 0usize;
    for &i in &large[..nl] {
        let value = if upper_num > 0 { (16*p[i]*upper_den/upper_num) as usize } else { 0 };
        for q in (0..=reachable).rev() { if dpw[q] <= cap { let dst = q + value; let nw = dpw[q] + w[i]; let nm = dpm[q] | (1i64 << i); if nw < dpw[dst] || nw == dpw[dst] && nm < dpm[dst] { dpw[dst] = nw; dpm[dst] = nm; } } }
        reachable += value;
    }
    let mut best_mask = 0i64; let mut best_profit = 0i64;
    for q in 0..=reachable { if dpw[q] <= cap { let mut mask = dpm[q]; let mut value = 0i64; let mut remaining = cap-dpw[q]; for i in 0..n { if ((mask as u64 >> i) & 1) != 0 { value += p[i]; } } for &i in &small[..ns] { if w[i] <= remaining { remaining -= w[i]; mask |= 1i64 << i; value += p[i]; } } if value > best_profit || value == best_profit && mask < best_mask { best_profit = value; best_mask = mask; } } }
    store(output, 0, best_mask); store(output, 8, best_profit); 16
}
