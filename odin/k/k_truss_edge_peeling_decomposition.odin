// Clean-room bounded edge-peeling truss decomposition.
package k_truss_edge_peeling_decomposition

import "core:c"

MAX_N :: 16
MAX_M :: 120
MAX_PARSEABLE_INPUT :: 243

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
k_truss_edge_peeling_decomposition :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2+2*m) || length > 242 do return -1
    adjacency: [MAX_N*MAX_N]bool
    edge_index: [MAX_N*MAX_N]int
    for cell := 0; cell < MAX_N*MAX_N; cell += 1 { edge_index[cell] = -1 }
    edge_u: [MAX_M]int
    edge_v: [MAX_M]int
    support: [MAX_M]int
    alive: [MAX_M]bool
    trussness: [MAX_M]i64
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[2+2*edge], input[3+2*edge]
        if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if adjacency[u*MAX_N+v] do return -1
        adjacency[u*MAX_N+v], adjacency[v*MAX_N+u] = true, true
        edge_index[u*MAX_N+v], edge_index[v*MAX_N+u] = edge, edge
        edge_u[edge], edge_v[edge], alive[edge] = u, v, true
    }
    for u := 0; u < n; u += 1 {
        for v := u+1; v < n; v += 1 {
            for w := v+1; w < n; w += 1 {
                if adjacency[u*MAX_N+v] && adjacency[u*MAX_N+w] && adjacency[v*MAX_N+w] {
                    support[edge_index[u*MAX_N+v]] += 1
                    support[edge_index[u*MAX_N+w]] += 1
                    support[edge_index[v*MAX_N+w]] += 1
                }
            }
        }
    }
    output_bytes := 8*m
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    remaining := m
    level := 0
    for remaining > 0 {
        selected := -1
        for edge := 0; edge < m; edge += 1 {
            if alive[edge] && (selected < 0 || support[edge] < support[selected]) { selected = edge }
        }
        if support[selected] > level { level = support[selected] }
        trussness[selected] = i64(level+2)
        alive[selected] = false
        remaining -= 1
        u, v := edge_u[selected], edge_v[selected]
        for w := 0; w < n; w += 1 {
            if w == u || w == v || !adjacency[u*MAX_N+w] || !adjacency[v*MAX_N+w] do continue
            first, second := edge_index[u*MAX_N+w], edge_index[v*MAX_N+w]
            if alive[first] && alive[second] {
                if support[first] > level { support[first] -= 1 }
                if support[second] > level { support[second] -= 1 }
            }
        }
    }
    for edge := 0; edge < m; edge += 1 { store_i64_le(output, 8*edge, trussness[edge]) }
    return i64(output_bytes)
}
