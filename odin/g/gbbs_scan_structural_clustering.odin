// Clean-room bounded GBBS SCAN profile; see package LICENSE.txt.
package gbbs_scan_structural_clustering

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

similarity_parts :: proc(u, v: int, adjacent: [MAX_N][MAX_N]bool,
    degree: [MAX_N]int) -> (u64, u64) {
    shared: u64 = 0
    for w := 0; w < MAX_N; w += 1 {
        if adjacent[u][w] && adjacent[v][w] do shared += 1
    }
    return shared + 2, u64((degree[u] + 1) * (degree[v] + 1))
}

epsilon_similar :: proc(numerator, denominator_sq: u64) -> bool {
    return 4 * numerator * numerator >= denominator_sq
}

@(export)
gbbs_scan_structural_clustering :: proc "c" (input: [^]i64, length: c.size_t,
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
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    core: [MAX_N]bool
    labels: [MAX_N]i64
    for u := 0; u < n; u += 1 {
        similar_count := 0
        for v := 0; v < n; v += 1 {
            if adjacent[u][v] {
                numerator, denominator_sq := similarity_parts(u, v, adjacent, degree)
                if epsilon_similar(numerator, denominator_sq) do similar_count += 1
            }
        }
        core[u] = similar_count >= 2
        labels[u] = -1
    }
    for root := 0; root < n; root += 1 {
        if !core[root] || labels[root] != -1 do continue
        queue: [MAX_N]int
        head, tail := 0, 1
        labels[root] = i64(root)
        queue[0] = root
        for head < tail {
            u := queue[head]
            head += 1
            for v := 0; v < n; v += 1 {
                if !core[v] || labels[v] != -1 || !adjacent[u][v] do continue
                numerator, denominator_sq := similarity_parts(u, v, adjacent, degree)
                if epsilon_similar(numerator, denominator_sq) {
                    labels[v] = i64(root)
                    queue[tail] = v
                    tail += 1
                }
            }
        }
    }
    for u := 0; u < n; u += 1 {
        if core[u] do continue
        best_core, best_num, best_den := MAX_N, u64(0), u64(1)
        for v := 0; v < n; v += 1 {
            if !core[v] || !adjacent[u][v] do continue
            numerator, denominator_sq := similarity_parts(u, v, adjacent, degree)
            if !epsilon_similar(numerator, denominator_sq) do continue
            left := numerator * numerator * best_den
            right := best_num * best_num * denominator_sq
            if best_core == MAX_N || left > right || (left == right && v < best_core) {
                best_core, best_num, best_den = v, numerator, denominator_sq
            }
        }
        if best_core != MAX_N do labels[u] = labels[best_core]
    }
    for v := 0; v < n; v += 1 { store_i64_le(output, 8*v, labels[v]) }
    return i64(output_bytes)
}
