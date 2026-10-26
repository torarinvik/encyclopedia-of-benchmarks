// Clean-room bounded GBBS Barenboim-Elkin profile; see package LICENSE.txt.
const N: usize = 20;
const M: usize = 190;
const INPUT: usize = 2 + 2 * M;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let mut bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits & 255) as u8; } bits >>= 8; }
}

#[no_mangle]
pub unsafe extern "C" fn gbbs_barenboim_elkin_degeneracy_order(input: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > INPUT { return -1; }
    let n64 = *input; let m64 = *input.add(1);
    if n64 < 1 || n64 > N as i64 || m64 < 0 || m64 > M as i64 || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize; let m = m64 as usize;
    let mut adjacent = [[false; N]; N];
    let mut initial_degree = [0i64; N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge); let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize; let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true; adjacent[v][u] = true;
        initial_degree[u] += 1; initial_degree[v] += 1;
    }
    if output.is_null() || capacity < 8 * n { return -2; }
    let mut degree = initial_degree;
    let mut alive = [false; N];
    for v in 0..n { alive[v] = true; }
    let mut remaining = n;
    let (mut best_num, mut best_den) = (0i64, 1i64);
    while remaining > 0 {
        let mut total = 0i64;
        for v in 0..n { if alive[v] { total += degree[v]; } }
        if total * best_den > best_num * remaining as i64 { best_num = total; best_den = remaining as i64; }
        let mut removed = [false; N]; let mut count = 0;
        for v in 0..n {
            if alive[v] && 10 * degree[v] * remaining as i64 <= 11 * total { removed[v] = true; count += 1; }
        }
        if count == 0 { return -1; }
        for v in 0..n { if removed[v] { alive[v] = false; } }
        remaining -= count;
        for v in 0..n { if alive[v] {
            let mut dec = 0i64;
            for u in 0..n { if removed[u] && adjacent[v][u] { dec += 1; } }
            degree[v] -= dec;
        } }
    }
    let cutoff = std::cmp::max((best_num + 10 * best_den - 1) / (10 * best_den), 1);
    let mut degree = initial_degree;
    let mut alive = [false; N];
    for v in 0..n { alive[v] = true; }
    let mut order = [0usize; N]; let mut used = 0;
    while used < n {
        let mut shell = [0usize; N]; let mut count = 0;
        for v in 0..n { if alive[v] && degree[v] < cutoff { shell[count] = v; count += 1; } }
        if count == 0 { for v in 0..n { if alive[v] { shell[count] = v; count += 1; break; } } }
        for i in 0..count { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
        for v in 0..n { if alive[v] {
            let mut dec = 0i64;
            for i in 0..count { if adjacent[v][shell[i]] { dec += 1; } }
            degree[v] -= dec;
        } }
    }
    let mut rank = [0i64; N];
    for i in 0..n { rank[order[i]] = i as i64; }
    for v in 0..n { store_i64_le(output, 8 * v, rank[v]); }
    (8 * n) as i64
}
