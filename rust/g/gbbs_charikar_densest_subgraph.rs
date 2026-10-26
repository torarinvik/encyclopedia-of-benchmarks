// Clean-room bounded GBBS Charikar profile; see package LICENSE.txt.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn gbbs_charikar_densest_subgraph(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_M { return INVALID_RESULT; }
    let n64 = *input; let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return INVALID_RESULT; }
    let n = n64 as usize; let m = m64 as usize;
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut degree = [0i32; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge); let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return INVALID_RESULT; }
        let u = u64 as usize; let v = v64 as usize;
        if adjacent[u][v] { return INVALID_RESULT; }
        adjacent[u][v] = true; adjacent[v][u] = true; degree[u] += 1; degree[v] += 1;
    }
    let mut alive = [false; MAX_N]; let mut order = [0usize; MAX_N]; let mut position = [0usize; MAX_N];
    for v in 0..n { alive[v] = true; }
    let mut used = 0;
    while used < n {
        let mut level = MAX_M as i32;
        for v in 0..n { if alive[v] && degree[v] < level { level = degree[v]; } }
        loop {
            let mut shell = [0usize; MAX_N]; let mut count = 0;
            for v in 0..n { if alive[v] && degree[v] == level { shell[count] = v; count += 1; } }
            if count == 0 { break; }
            for i in 0..count { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
            for v in 0..n { if alive[v] {
                let mut removed = 0;
                for i in 0..count { if adjacent[v][shell[i]] { removed += 1; } }
                degree[v] = std::cmp::max(degree[v] - removed, level);
            } }
        }
    }
    for i in 0..n { position[order[i]] = i; }
    let mut best = 0.0f64;
    for start in 0..n {
        let mut edges = 0;
        for u in 0..n { if position[u] >= start { for v in u + 1..n {
            if position[v] >= start && adjacent[u][v] { edges += 1; }
        } } }
        let score = 2.0 * edges as f64 / (n - start) as f64;
        if score > best { best = score; }
    }
    if best.is_finite() { best } else { INVALID_RESULT }
}
