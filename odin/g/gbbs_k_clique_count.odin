// Clean-room GBBS fixed-k clique profile; see package LICENSE.txt.
package gbbs_k_clique_count

import "core:c"

MAX_N :: 24
MAX_M :: 64
MAX_INPUT :: 130

store_i64_le :: proc(output: [^]u8, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gbbs_k_clique_count :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2 + 2*m) do return -1
    adjacent: [MAX_N][MAX_N]bool
    degree: [MAX_N]int
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[2+2*edge], input[3+2*edge]
        if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if adjacent[u][v] do return -1
        adjacent[u][v], adjacent[v][u] = true, true
        degree[u] += 1
        degree[v] += 1
    }
    if output == nil || capacity < 8 do return -2

    directed: [MAX_N][MAX_N]bool
    for u := 0; u < n; u += 1 {
        if degree[u] >= 3 {
            for v := u + 1; v < n; v += 1 {
                if degree[v] >= 3 && adjacent[u][v] do directed[u][v] = true
            }
        }
    }
    count: i64 = 0
    for a := 0; a < n; a += 1 {
        for b := a + 1; b < n; b += 1 {
            if !directed[a][b] do continue
            for c0 := b + 1; c0 < n; c0 += 1 {
                if !(directed[a][c0] && directed[b][c0]) do continue
                for d := c0 + 1; d < n; d += 1 {
                    if directed[a][d] && directed[b][d] && directed[c0][d] do count += 1
                }
            }
        }
    }
    store_i64_le(output, count)
    return 8
}
