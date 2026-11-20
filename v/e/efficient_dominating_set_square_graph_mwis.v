module efficient_dominating_set_square_graph_mwis

const max_vertices = 12

fn bit_count(bits0 u16) int {
    mut bits := bits0
    mut count := 0
    for bits != 0 { bits &= bits - 1; count++ }
    return count
}

fn weighted_mis(square [max_vertices]u16, weights [max_vertices]int, remaining u16, current int, mut best int) {
    mut upper := current
    for v in 0 .. max_vertices { if (remaining & (u16(1) << v)) != 0 { upper += weights[v] } }
    if upper <= best { return }
    if remaining == 0 { best = current; return }
    mut branch := 0
    mut branch_degree := -1
    for v in 0 .. max_vertices {
        if (remaining & (u16(1) << v)) == 0 { continue }
        degree := bit_count(square[v] & remaining)
        if degree > branch_degree { branch = v; branch_degree = degree }
    }
    bit := u16(1) << branch
    weighted_mis(square, weights, remaining & ~bit & ~square[branch], current + weights[branch], mut best)
    weighted_mis(square, weights, remaining & ~bit, current, mut best)
}

@[export: 'efficient_dominating_set_square_graph_mwis']
pub fn efficient_dominating_set_square_graph_mwis(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 2 || length > 135 { return -1 }
        n64 := input[0]
        m64 := input[1]
        if n64 < 1 || n64 > max_vertices || m64 < 0 || m64 > n64 * (n64 - 1) / 2 { return -1 }
        if i64(length) != 2 + 2 * m64 { return -1 }
        mut adjacency := [max_vertices]u16{}
        for e in 0 .. int(m64) {
            u64 := input[2 + 2 * e]
            v64 := input[3 + 2 * e]
            if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1 }
            u := int(u64)
            v := int(v64)
            bit := u16(1) << v
            if (adjacency[u] & bit) != 0 { return -1 }
            adjacency[u] |= bit
            adjacency[v] |= u16(1) << u
        }
        mut square := [max_vertices]u16{}
        mut weights := [max_vertices]int{}
        for v in 0 .. int(n64) {
            square[v] = adjacency[v]
            for u in 0 .. int(n64) { if (adjacency[v] & (u16(1) << u)) != 0 { square[v] |= adjacency[u] } }
            square[v] &= ~(u16(1) << v)
            weights[v] = bit_count(adjacency[v]) + 1
        }
        mut best := 0
        all := (u16(1) << int(n64)) - 1
        weighted_mis(square, weights, all, 0, mut best)
        return if best == int(n64) { 1 } else { 0 }
    }
}
