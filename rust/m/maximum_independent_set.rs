/// Exact MIS by maximum-degree branching and a greedy clique-cover bound.
const MAX_N: usize = 22;
const MAX_INPUT: usize = 465;

fn popcount(bits: u64) -> i64 { bits.count_ones() as i64 }

fn clique_cover_bound(adjacency: &[u64; MAX_N], mut remaining: u64) -> i64 {
    let mut cliques = 0;
    while remaining != 0 {
        cliques += 1;
        let mut candidates = remaining;
        while candidates != 0 {
            let bit = candidates & candidates.wrapping_neg();
            let vertex = bit.trailing_zeros() as usize;
            remaining &= !bit;
            candidates &= !bit;
            candidates &= adjacency[vertex];
        }
    }
    cliques
}

fn search_mis(adjacency: &[u64; MAX_N], remaining: u64, chosen: i64, best: &mut i64) {
    if remaining == 0 { *best = (*best).max(chosen); return; }
    if chosen + popcount(remaining) <= *best { return; }
    if chosen + clique_cover_bound(adjacency, remaining) <= *best { return; }
    let mut vertices = remaining;
    let mut branch = 0usize;
    let mut branch_degree = -1i64;
    while vertices != 0 {
        let bit = vertices & vertices.wrapping_neg();
        let vertex = bit.trailing_zeros() as usize;
        let degree = popcount(adjacency[vertex] & remaining);
        if degree > branch_degree { branch = vertex; branch_degree = degree; }
        vertices &= !bit;
    }
    let bit = 1u64 << branch;
    search_mis(adjacency, remaining & !bit & !adjacency[branch], chosen + 1, best);
    search_mis(adjacency, remaining & !bit, chosen, best);
}

#[no_mangle]
pub unsafe extern "C" fn maximum_independent_set(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(packed, length);
    let n64 = input[0];
    let m64 = input[1];
    if !(0..=MAX_N as i64).contains(&n64) { return -1; }
    let max_edges = n64 * (n64 - 1) / 2;
    if m64 < 0 || m64 > max_edges || length != 2 + 2 * m64 as usize { return -1; }
    let mut adjacency = [0u64; MAX_N];
    for edge in 0..m64 as usize {
        let u64 = input[2 + 2 * edge];
        let v64 = input[3 + 2 * edge];
        if u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 || u64 == v64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        let v_bit = 1u64 << v;
        if adjacency[u] & v_bit != 0 { return -1; }
        adjacency[u] |= v_bit;
        adjacency[v] |= 1u64 << u;
    }
    let mut best = 0;
    search_mis(&adjacency, (1u64 << n64 as usize) - 1, 0, &mut best);
    best
}
