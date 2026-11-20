package efficient_dominating_set_square_graph_mwis

// Efficient domination via weighted independent set on the square graph.
import "core:c"

MAX_VERTICES :: 12

bit_count :: proc(bits0: u16) -> int {
    bits := bits0
    count := 0
    for bits != 0 {
        bits &= bits - 1
        count += 1
    }
    return count
}

weighted_mis :: proc(square: [MAX_VERTICES]u16, weights: [MAX_VERTICES]int,
                     remaining: u16, current: int, best: ^int) {
    upper := current
    for v in 0..<MAX_VERTICES {
        if (remaining & (u16(1) << v)) != 0 { upper += weights[v] }
    }
    if upper <= best^ { return }
    if remaining == 0 { best^ = current; return }
    branch, branch_degree := -1, -1
    for v in 0..<MAX_VERTICES {
        if (remaining & (u16(1) << v)) == 0 { continue }
        degree := bit_count(square[v] & remaining)
        if degree > branch_degree { branch = v; branch_degree = degree }
    }
    bit := u16(1) << branch
    weighted_mis(square, weights, remaining & ~bit & ~square[branch], current + weights[branch], best)
    weighted_mis(square, weights, remaining & ~bit, current, best)
}

@(export)
efficient_dominating_set_square_graph_mwis :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 135 { return -1 }
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_VERTICES || m64 < 0 || m64 > n64 * (n64 - 1) / 2 { return -1 }
    if i64(length) != 2 + 2 * m64 { return -1 }
    n := int(n64)
    adjacency: [MAX_VERTICES]u16
    for e in 0..<int(m64) {
        u64, v64 := input[2 + 2 * e], input[3 + 2 * e]
        if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1 }
        u, v := int(u64), int(v64)
        bit := u16(1) << v
        if (adjacency[u] & bit) != 0 { return -1 }
        adjacency[u] |= bit
        adjacency[v] |= u16(1) << u
    }
    square: [MAX_VERTICES]u16
    weights: [MAX_VERTICES]int
    for v in 0..<n {
        square[v] = adjacency[v]
        for u in 0..<n {
            if (adjacency[v] & (u16(1) << u)) != 0 { square[v] |= adjacency[u] }
        }
        square[v] &^= u16(1) << v
        weights[v] = bit_count(adjacency[v]) + 1
    }
    best := 0
    all := (u16(1) << n) - 1
    weighted_mis(square, weights, all, 0, &best)
    if best == n { return 1 }
    return 0
}
