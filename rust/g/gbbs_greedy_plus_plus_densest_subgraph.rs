// Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt.
const N: usize = 16;
const M: usize = 64;
const MAX_INPUT: usize = 2 + 2 * M + 2;
const INVALID: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn gbbs_greedy_plus_plus_densest_subgraph(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return INVALID; }
    let n64 = *input; let m64 = *input.add(1);
    if n64 < 10 || n64 > N as i64 || m64 < 0 || m64 > M as i64
        || length != 2 + 2 * m64 as usize { return INVALID; }
    let n = n64 as usize; let m = m64 as usize;
    let mut adjacent = [[false; N]; N];
    let mut load = [0i64; N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge); let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return INVALID; }
        let u = u64 as usize; let v = v64 as usize;
        if adjacent[u][v] { return INVALID; }
        adjacent[u][v] = true; adjacent[v][u] = true;
        load[u] += 1; load[v] += 1;
    }
    let mut best = 0.0f64;
    for _round in 0..20 {
        let mut degree = load;
        let mut alive = [false; N];
        let mut order = [0usize; N];
        let mut position = [0usize; N];
        for v in 0..n { alive[v] = true; }
        let mut used = 0;
        while used < n {
            let mut level = i64::MAX;
            for v in 0..n { if alive[v] && degree[v] < level { level = degree[v]; } }
            let mut shell = [0usize; N]; let mut count = 0;
            for v in 0..n { if alive[v] && degree[v] == level { shell[count] = v; count += 1; } }
            for i in 0..count { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
            for v in 0..n { if alive[v] {
                let mut removed = 0i64;
                for i in 0..count { if adjacent[v][shell[i]] { removed += 1; } }
                degree[v] = std::cmp::max(degree[v] - removed, level);
            } }
        }
        for i in 0..n { position[order[i]] = i; }
        let mut density_above = [0i64; N];
        for v in 0..n {
            let mut later = 0i64;
            for u in 0..n { if adjacent[v][u] && position[u] > position[v] { later += 1; } }
            density_above[position[v]] = 2 * later;
            load[v] += later;
        }
        let mut suffix_sum = 0i64;
        for i in (0..n).rev() {
            suffix_sum += density_above[i];
            best = best.max(suffix_sum as f64 / (n - i) as f64);
        }
    }
    if best.is_finite() { best } else { INVALID }
}
