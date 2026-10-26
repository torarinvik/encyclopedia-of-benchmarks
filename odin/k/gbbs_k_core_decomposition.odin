// Clean-room bounded GBBS k-core profile; see package LICENSE.txt.
package gbbs_k_core_decomposition

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 130

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gbbs_k_core_decomposition :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2+2*m) do return -1
    adjacency: [MAX_N*MAX_N]bool
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[2+2*edge], input[3+2*edge]
        if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if adjacency[u*MAX_N+v] do return -1
        adjacency[u*MAX_N+v], adjacency[v*MAX_N+u] = true, true
    }
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    degree: [MAX_N]int
    core: [MAX_N]i64
    alive: [MAX_N]bool
    shell: [MAX_N]bool
    for u := 0; u < n; u += 1 {
        alive[u] = true
        for v := 0; v < n; v += 1 { if adjacency[u*MAX_N+v] { degree[u] += 1 } }
    }
    remaining := n
    for remaining > 0 {
        k := n
        for u := 0; u < n; u += 1 { if alive[u] && degree[u] < k { k = degree[u] } }
        for u := 0; u < n; u += 1 {
            shell[u] = alive[u] && degree[u] == k
            if shell[u] { alive[u] = false; core[u] = i64(k); remaining -= 1 }
        }
        for v := 0; v < n; v += 1 {
            if !alive[v] do continue
            removed := 0
            for u := 0; u < n; u += 1 { if shell[u] && adjacency[u*MAX_N+v] { removed += 1 } }
            if removed > 0 { degree[v] = max(degree[v]-removed, k) }
        }
    }
    for u := 0; u < n; u += 1 { store_i64_le(output, 8*u, core[u]) }
    return i64(output_bytes)
}
