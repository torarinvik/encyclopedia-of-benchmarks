// Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile.
#[no_mangle]
pub unsafe extern "C" fn gbbs_goodrich_pszona_degeneracy_order(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    const MAX_N: usize = 20;
    const MAX_M: usize = 190;
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_M { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64 { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != 2 + 2 * m { return -1; }
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
    if output.is_null() || capacity < 8 * n { return -2; }
    let mut degree = [0usize; MAX_N];
    let mut remaining = [false; MAX_N];
    let mut rank = [0i64; MAX_N];
    for vertex in 0..n {
        remaining[vertex] = true;
        for neighbor in 0..n { if adjacent[vertex][neighbor] { degree[vertex] += 1; } }
    }
    for position in 0..n {
        let mut chosen = n;
        for vertex in 0..n {
            if remaining[vertex] && (chosen == n || degree[vertex] < degree[chosen]) {
                chosen = vertex;
            }
        }
        rank[chosen] = position as i64;
        remaining[chosen] = false;
        for neighbor in 0..n {
            if remaining[neighbor] && adjacent[chosen][neighbor] { degree[neighbor] -= 1; }
        }
    }
    for vertex in 0..n {
        let bits = rank[vertex] as u64;
        for byte in 0..8 { *output.add(8 * vertex + byte) = (bits >> (8 * byte)) as u8; }
    }
    (8 * n) as i64
}
