/// Efficient domination via weighted independent set on the square graph.
const MAX_VERTICES: usize = 12;

fn bit_count(mut bits: u16) -> i32 {
    let mut count = 0;
    while bits != 0 { bits &= bits - 1; count += 1; }
    count
}

fn weighted_mis(square: &[u16; MAX_VERTICES], weights: &[i32; MAX_VERTICES],
                remaining: u16, current: i32, best: &mut i32) {
    let mut upper = current;
    for v in 0..MAX_VERTICES {
        if remaining & (1u16 << v) != 0 { upper += weights[v]; }
    }
    if upper <= *best { return; }
    if remaining == 0 { *best = current; return; }
    let mut branch = 0;
    let mut branch_degree = -1;
    for v in 0..MAX_VERTICES {
        if remaining & (1u16 << v) == 0 { continue; }
        let degree = bit_count(square[v] & remaining);
        if degree > branch_degree { branch = v; branch_degree = degree; }
    }
    let bit = 1u16 << branch;
    weighted_mis(square, weights, remaining & !bit & !square[branch], current + weights[branch], best);
    weighted_mis(square, weights, remaining & !bit, current, best);
}

#[no_mangle]
pub extern "C" fn efficient_dominating_set_square_graph_mwis(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 135 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (n64, m64) = (values[0], values[1]);
    if !(1..=MAX_VERTICES as i64).contains(&n64) || m64 < 0 || m64 > n64 * (n64 - 1) / 2
        || length != 2 + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let mut adjacency = [0u16; MAX_VERTICES];
    for e in 0..m64 as usize {
        let (u64, v64) = (values[2 + 2 * e], values[3 + 2 * e]);
        if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1; }
        let (u, v) = (u64 as usize, v64 as usize);
        let bit = 1u16 << v;
        if adjacency[u] & bit != 0 { return -1; }
        adjacency[u] |= bit;
        adjacency[v] |= 1u16 << u;
    }
    let mut square = [0u16; MAX_VERTICES];
    let mut weights = [0i32; MAX_VERTICES];
    for v in 0..n {
        square[v] = adjacency[v];
        for u in 0..n { if adjacency[v] & (1u16 << u) != 0 { square[v] |= adjacency[u]; } }
        square[v] &= !(1u16 << v);
        weights[v] = bit_count(adjacency[v]) + 1;
    }
    let mut best = 0;
    weighted_mis(&square, &weights, (1u16 << n) - 1, 0, &mut best);
    if best == n as i32 { 1 } else { 0 }
}
