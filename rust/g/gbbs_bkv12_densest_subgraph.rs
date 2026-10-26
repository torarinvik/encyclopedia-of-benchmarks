// Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt.
const N: usize = 16;
const M: usize = 64;
const MAX_INPUT: usize = 2 + 2 * M + 2;
const INVALID: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn gbbs_bkv12_densest_subgraph(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return INVALID; }
    let n64 = *input; let m64 = *input.add(1);
    if !(1..=N as i64).contains(&n64) || !(0..=M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize { return INVALID; }
    let n = n64 as usize; let m = m64 as usize;
    let mut adjacent = [[false; N]; N];
    let mut degree = [0i64; N];
    let mut edge_u = [0usize; M]; let mut edge_v = [0usize; M];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge); let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return INVALID; }
        let u = u64 as usize; let v = v64 as usize;
        if adjacent[u][v] { return INVALID; }
        adjacent[u][v] = true; adjacent[v][u] = true;
        degree[u] += 1; degree[v] += 1; edge_u[edge] = u; edge_v[edge] = v;
    }
    let mut alive = [false; N];
    for vertex in 0..n { alive[vertex] = true; }
    let mut remaining = n;
    let mut best = 0.0f64;
    while remaining > 0 {
        let mut total = 0i64;
        for vertex in 0..n { if alive[vertex] { total += degree[vertex]; } }
        let density = total as f64 / remaining as f64;
        if density > best { best = density; }
        let mut removed = [false; N]; let mut count = 0;
        for vertex in 0..n {
            if alive[vertex] && 1000 * degree[vertex] * remaining as i64 <= 1001 * total {
                removed[vertex] = true; count += 1;
            }
        }
        if count == 0 { return INVALID; }
        for vertex in 0..n { if removed[vertex] { alive[vertex] = false; } }
        remaining -= count;
        for edge in 0..m {
            let (u, v) = (edge_u[edge], edge_v[edge]);
            if removed[u] && alive[v] { degree[v] -= 1; }
            if removed[v] && alive[u] { degree[u] -= 1; }
        }
    }
    if best.is_finite() { best } else { INVALID }
}
