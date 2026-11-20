// Independently authored bounded subset-assignment draft; unverified.
#[no_mangle]
pub unsafe extern "C" fn tree_sibling_distinct_cost_coloring(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=354).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=32).contains(&values[0]) || !(1..=10).contains(&values[1]) { return -1; }
    let (n, k) = (values[0] as usize, values[1] as usize);
    if length != n + 1 + n * k { return -1; }
    for vertex in 1..n {
        if values[1 + vertex] < 0 || values[1 + vertex] >= vertex as i64 { return -1; }
    }
    if values[n+1..].iter().any(|&cost| !(0..=1_000_000).contains(&cost)) { return -1; }
    const INF: i64 = 1_000_000_000_000;
    let mut dp = [[0i64; 10]; 32];
    let states = 1usize << k;
    let mut current = [INF; 1024];
    let mut next = [INF; 1024];
    for vertex in (0..n).rev() {
        for color in 0..k {
            current[..states].fill(INF);
            current[1 << color] = 0;
            for child in vertex+1..n {
                if values[1 + child] != vertex as i64 { continue; }
                next[..states].fill(INF);
                for mask in 0..states {
                    if current[mask] == INF { continue; }
                    for c in 0..k {
                        if mask & (1 << c) != 0 || dp[child][c] == INF { continue; }
                        let extended = mask | (1 << c);
                        next[extended] = next[extended].min(current[mask] + dp[child][c]);
                    }
                }
                current[..states].copy_from_slice(&next[..states]);
            }
            let best = *current[..states].iter().min().unwrap();
            dp[vertex][color] = if best == INF { INF } else { best + values[n+1+vertex*k+color] };
        }
    }
    let best = *dp[0][..k].iter().min().unwrap();
    if best == INF { -2 } else { best }
}
