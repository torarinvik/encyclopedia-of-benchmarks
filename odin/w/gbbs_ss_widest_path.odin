// Clean-room bounded GBBS widest-path profile; see package LICENSE.txt.
package gbbs_ss_widest_path

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 195
SOURCE_INFINITY :: i64(2_147_483_647)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gbbs_ss_widest_path :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    n64, m64, source64 := input[0], input[1], input[2]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || source64 < 0 ||
        source64 >= n64 || length != c.size_t(3+3*m64) do return -1
    n, m, source := int(n64), int(m64), int(source64)
    edge_from: [MAX_M]int
    edge_to: [MAX_M]int
    edge_capacity: [MAX_M]i64
    for edge := 0; edge < m; edge += 1 {
        from, to, edge_width := input[3+3*edge], input[4+3*edge], input[5+3*edge]
        if from < 0 || from >= n64 || to < 0 || to >= n64 || edge_width < 1 || edge_width > 32 do return -1
        edge_from[edge], edge_to[edge], edge_capacity[edge] = int(from), int(to), edge_width
    }
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    width: [MAX_N]i64
    settled: [MAX_N]bool
    width[source] = SOURCE_INFINITY
    for step := 0; step < n; step += 1 {
        u := n
        for vertex := 0; vertex < n; vertex += 1 {
            if !settled[vertex] && (u == n || width[vertex] > width[u]) do u = vertex
        }
        if u == n || width[u] == 0 do break
        settled[u] = true
        for edge := 0; edge < m; edge += 1 {
            if edge_from[edge] != u do continue
            v := edge_to[edge]
            if settled[v] do continue
            candidate := width[u]
            if edge_capacity[edge] < candidate do candidate = edge_capacity[edge]
            if candidate > width[v] do width[v] = candidate
        }
    }
    for vertex := 0; vertex < n; vertex += 1 { store_i64_le(output, 8*vertex, width[vertex]) }
    return i64(output_bytes)
}
