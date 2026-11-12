const MAX_N: usize = 8;
const MAX_M: usize = 14;
const MAX_K: usize = 5;
const MAX_INPUT: usize = 50;
const MAX_MASKS: usize = 1 << MAX_K;
const INF: i64 = 1_000_000_000_000_000_000;

fn solve(input: &[i64]) -> i64 {
    if input.len() < 3 || input.len() > MAX_INPUT { return -1; }
    let (n0, m0, k0) = (input[0], input[1], input[2]);
    if n0 < 1 || n0 > MAX_N as i64 || m0 < 0 || m0 > MAX_M as i64
        || k0 < 1 || k0 > MAX_K as i64 || k0 > n0 { return -1; }
    let (n, m, k) = (n0 as usize, m0 as usize, k0 as usize);
    if m > n * (n - 1) / 2 || input.len() != 3 + k + 3 * m { return -1; }

    let mut terminal_seen = [false; MAX_N];
    let mut terminals = [0usize; MAX_K];
    for i in 0..k {
        let vertex = input[3 + i];
        if vertex < 0 || vertex >= n as i64 || terminal_seen[vertex as usize] { return -1; }
        terminal_seen[vertex as usize] = true;
        terminals[i] = vertex as usize;
    }

    let mut present = [[false; MAX_N]; MAX_N];
    let mut weight = [[0i64; MAX_N]; MAX_N];
    for i in 0..m {
        let (u0, v0, w) = (input[3 + k + 3 * i], input[4 + k + 3 * i], input[5 + k + 3 * i]);
        if u0 < 0 || u0 >= v0 || v0 >= n as i64 || !(0..=1000).contains(&w) { return -1; }
        let (u, v) = (u0 as usize, v0 as usize);
        if present[u][v] { return -1; }
        present[u][v] = true;
        present[v][u] = true;
        weight[u][v] = w;
        weight[v][u] = w;
    }

    let mut dp = [[INF; MAX_N]; MAX_MASKS];
    for bit in 0..k { dp[1 << bit][terminals[bit]] = 0; }
    let masks = 1 << k;
    for mask in 1..masks {
        if mask & (mask - 1) != 0 {
            let mut sub = (mask - 1) & mask;
            while sub != 0 {
                let other = mask ^ sub;
                if sub < other {
                    for v in 0..n {
                        if dp[sub][v] < INF && dp[other][v] < INF {
                            let candidate = dp[sub][v] + dp[other][v];
                            if candidate < dp[mask][v] { dp[mask][v] = candidate; }
                        }
                    }
                }
                sub = (sub - 1) & mask;
            }
        }
        let mut used = [false; MAX_N];
        for _ in 0..n {
            let mut chosen: Option<usize> = None;
            for v in 0..n {
                if !used[v] && chosen.map_or(true, |u| dp[mask][v] < dp[mask][u]) { chosen = Some(v); }
            }
            let Some(u) = chosen else { break; };
            if dp[mask][u] >= INF { break; }
            used[u] = true;
            for v in 0..n {
                if present[u][v] && !used[v] {
                    let candidate = dp[mask][u] + weight[u][v];
                    if candidate < dp[mask][v] { dp[mask][v] = candidate; }
                }
            }
        }
    }
    let answer = dp[masks - 1][..n].iter().copied().min().unwrap_or(INF);
    if answer >= INF { -2 } else { answer }
}

#[no_mangle]
pub unsafe extern "C" fn steiner_tree_subset_dp(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length > MAX_INPUT { return -1; }
    if length < 3 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
