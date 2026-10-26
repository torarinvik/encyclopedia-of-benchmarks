const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 2 + 3 * MAX_M;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn gbbs_maximal_matching(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || length != 2 + 3 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mut rank_seen = [false; MAX_M];
    let mut order = [0usize; MAX_M];
    let mut adjacency = [[false; MAX_N]; MAX_N];
    let edge_start = 2 + m;
    for edge in 0..m {
        let rank64 = *input.add(2 + edge);
        if rank64 < 0 || rank64 >= m64 { return -1; }
        let rank = rank64 as usize;
        if rank_seen[rank] { return -1; }
        rank_seen[rank] = true;
        order[rank] = edge;
        let u64 = *input.add(edge_start + 2 * edge);
        let v64 = *input.add(edge_start + 2 * edge + 1);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacency[u][v] { return -1; }
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    let output_bytes = 8 * m;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut matched = [false; MAX_N];
    let mut selected = [0i64; MAX_M];
    for rank in 0..m {
        let edge = order[rank];
        let u = *input.add(edge_start + 2 * edge) as usize;
        let v = *input.add(edge_start + 2 * edge + 1) as usize;
        if !matched[u] && !matched[v] {
            selected[edge] = 1;
            matched[u] = true;
            matched[v] = true;
        }
    }
    for edge in 0..m { store_i64_le(output, 8 * edge, selected[edge]); }
    output_bytes as i64
}
