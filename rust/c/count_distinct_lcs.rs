//! Uncompiled duplicate-aware distinct-LCS counting draft.
#[no_mangle]
pub unsafe extern "C" fn count_distinct_lcs(input: *const i64, length: usize) -> i64 {
    const MOD: i64 = 1_000_000_007;
    if input.is_null() || !(2..=131).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (nr, mr) = (values[0], values[1]);
    if !(0..=64).contains(&nr) || !(0..=64).contains(&mr) || length != (2+nr+mr) as usize { return -1; }
    if values[2..].iter().any(|v| !(0..=255).contains(v)) { return -1; }
    let (n, m) = (nr as usize, mr as usize);
    let (mut prev_len, mut curr_len) = ([0usize;65], [0usize;65]);
    let (mut prev_count, mut curr_count) = ([1i64;65], [0i64;65]);
    for i in 1..=n {
        curr_len[0] = 0; curr_count[0] = 1;
        for j in 1..=m {
            if values[1+i] == values[1+n+j] {
                curr_len[j] = prev_len[j-1]+1; curr_count[j] = prev_count[j-1];
            } else {
                let best = prev_len[j].max(curr_len[j-1]);
                let mut count = 0;
                if prev_len[j] == best { count += prev_count[j]; }
                if curr_len[j-1] == best { count += curr_count[j-1]; }
                if prev_len[j-1] == best { count -= prev_count[j-1]; }
                curr_len[j] = best; curr_count[j] = (count+MOD)%MOD;
            }
        }
        std::mem::swap(&mut prev_len, &mut curr_len);
        std::mem::swap(&mut prev_count, &mut curr_count);
    }
    prev_count[m]
}
