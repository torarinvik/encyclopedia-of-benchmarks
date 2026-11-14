//! Uncompiled bounded minimum-cost proper tree coloring draft.
#[no_mangle]
pub unsafe extern "C" fn tree_min_cost_proper_coloring(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=1090).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (nv, kv) = (values[0], values[1]);
    if !(1..=64).contains(&nv) || !(1..=16).contains(&kv) { return -1; }
    let (n, k) = (nv as usize, kv as usize);
    if length != n+1+n*k { return -1; }
    for v in 1..n { if values[1+v] < 0 || values[1+v] >= v as i64 { return -1; } }
    let mut dp = [[0i64; 16]; 64];
    for v in 0..n { for c in 0..k {
        let cost = values[n+1+v*k+c];
        if !(0..=1_000_000).contains(&cost) { return -1; }
        dp[v][c] = cost;
    } }
    if n>1 && k==1 { return -2; }
    for child in (1..n).rev() {
        let parent = values[1+child] as usize;
        let (mut least, mut second, mut least_color) = (i64::MAX, i64::MAX, 0);
        for c in 0..k {
            let cost = dp[child][c];
            if cost < least { second=least; least=cost; least_color=c; }
            else if cost < second { second=cost; }
        }
        for c in 0..k { dp[parent][c] += if c==least_color { second } else { least }; }
    }
    *dp[0][..k].iter().min().unwrap()
}
