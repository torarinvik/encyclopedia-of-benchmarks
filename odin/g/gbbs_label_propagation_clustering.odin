// Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt.
package gbbs_label_propagation_clustering

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
gbbs_label_propagation_clustering :: proc "c" (input: [^]i64, length: c.size_t,
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
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    labels: [MAX_N]i64
    for vertex := 0; vertex < n; vertex += 1 { labels[vertex] = i64(vertex) }
    for u := 0; u < n; u += 1 {
        frequency: [MAX_N]int
        degree := 0
        for v := 0; v < n; v += 1 {
            if adjacent[u][v] {
                frequency[int(labels[v])] += 1
                degree += 1
            }
        }
        if degree == 0 do continue
        best_label, best_frequency := 0, 0
        for label := 0; label < n; label += 1 {
            if frequency[label] > best_frequency ||
                (frequency[label] == best_frequency && frequency[label] > 0 && label > best_label) {
                best_label, best_frequency = label, frequency[label]
            }
        }
        labels[u] = i64(best_label)
    }
    for vertex := 0; vertex < n; vertex += 1 { store_i64_le(output, 8*vertex, labels[vertex]) }
    return i64(output_bytes)
}
