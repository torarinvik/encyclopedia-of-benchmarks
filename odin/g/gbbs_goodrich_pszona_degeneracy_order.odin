// Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile.
package gbbs_goodrich_pszona_degeneracy_order

import "core:c"

MAX_N :: 20
MAX_M :: 190
MAX_INPUT :: 382

store_i64_le :: proc(output: [^]u8, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gbbs_goodrich_pszona_degeneracy_order :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2 + 2*m) do return -1
    adjacent: [MAX_N][MAX_N]bool
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[2+2*edge], input[3+2*edge]
        if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if adjacent[u][v] do return -1
        adjacent[u][v], adjacent[v][u] = true, true
    }
    if output == nil || capacity < c.size_t(8*n) do return -2
    degree: [MAX_N]int
    remaining: [MAX_N]bool
    rank: [MAX_N]i64
    for vertex := 0; vertex < n; vertex += 1 {
        remaining[vertex] = true
        for neighbor := 0; neighbor < n; neighbor += 1 {
            if adjacent[vertex][neighbor] do degree[vertex] += 1
        }
    }
    for position := 0; position < n; position += 1 {
        chosen := n
        for vertex := 0; vertex < n; vertex += 1 {
            if remaining[vertex] && (chosen == n || degree[vertex] < degree[chosen]) do chosen = vertex
        }
        rank[chosen] = i64(position)
        remaining[chosen] = false
        for neighbor := 0; neighbor < n; neighbor += 1 {
            if remaining[neighbor] && adjacent[chosen][neighbor] do degree[neighbor] -= 1
        }
    }
    for vertex := 0; vertex < n; vertex += 1 {
        store_i64_le(output + 8*vertex, rank[vertex])
    }
    return i64(8*n)
}
