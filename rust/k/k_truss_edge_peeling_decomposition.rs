// Clean-room bounded edge-peeling truss decomposition.
const MAX_N: usize = 16;
const MAX_M: usize = 120;
const MAX_PARSEABLE_INPUT: usize = 243;

#[no_mangle]
pub unsafe extern "C" fn k_truss_edge_peeling_decomposition(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 2 * m64 as usize || length > 242 { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut adjacent = [[false; MAX_N]; MAX_N];
    let mut edge_index = [[-1i16; MAX_N]; MAX_N];
    let mut edge_u = [0usize; MAX_M];
    let mut edge_v = [0usize; MAX_M];
    let mut support = [0i32; MAX_M];
    let mut alive = [false; MAX_M];
    let mut trussness = [0i64; MAX_M];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        edge_index[u][v] = edge as i16;
        edge_index[v][u] = edge as i16;
        edge_u[edge] = u;
        edge_v[edge] = v;
        alive[edge] = true;
    }
    for u in 0..n { for v in u + 1..n { for w in v + 1..n {
        if adjacent[u][v] && adjacent[u][w] && adjacent[v][w] {
            support[edge_index[u][v] as usize] += 1;
            support[edge_index[u][w] as usize] += 1;
            support[edge_index[v][w] as usize] += 1;
        }
    } } }
    let output_bytes = 8 * m;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut remaining = m;
    let mut level = 0i32;
    while remaining > 0 {
        let mut selected = usize::MAX;
        for edge in 0..m {
            if alive[edge] && (selected == usize::MAX || support[edge] < support[selected]) { selected = edge; }
        }
        level = level.max(support[selected]);
        trussness[selected] = (level + 2) as i64;
        alive[selected] = false;
        remaining -= 1;
        let u = edge_u[selected];
        let v = edge_v[selected];
        for w in 0..n {
            if w == u || w == v || !adjacent[u][w] || !adjacent[v][w] { continue; }
            let first = edge_index[u][w] as usize;
            let second = edge_index[v][w] as usize;
            if alive[first] && alive[second] {
                if support[first] > level { support[first] -= 1; }
                if support[second] > level { support[second] -= 1; }
            }
        }
    }
    for edge in 0..m {
        let bits = trussness[edge] as u64;
        for byte in 0..8 { *output.add(8 * edge + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
