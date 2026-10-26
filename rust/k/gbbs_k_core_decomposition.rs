// Clean-room bounded GBBS k-core profile; see package LICENSE.txt.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 130;

#[no_mangle]
pub unsafe extern "C" fn gbbs_k_core_decomposition(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adjacent = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut degree = [0i32; MAX_N];
    let mut core = [0i64; MAX_N];
    let mut alive = [false; MAX_N];
    let mut shell = [false; MAX_N];
    for u in 0..n {
        alive[u] = true;
        degree[u] = adjacent[u][..n].iter().filter(|&&present| present).count() as i32;
    }
    let mut remaining = n;
    while remaining > 0 {
        let mut k = n as i32;
        for u in 0..n { if alive[u] && degree[u] < k { k = degree[u]; } }
        for u in 0..n {
            shell[u] = alive[u] && degree[u] == k;
            if shell[u] { alive[u] = false; core[u] = k as i64; remaining -= 1; }
        }
        for v in 0..n {
            if !alive[v] { continue; }
            let removed = (0..n).filter(|&u| shell[u] && adjacent[u][v]).count() as i32;
            if removed > 0 { degree[v] = (degree[v] - removed).max(k); }
        }
    }
    for u in 0..n {
        let bits = core[u] as u64;
        for byte in 0..8 { *output.add(8 * u + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
