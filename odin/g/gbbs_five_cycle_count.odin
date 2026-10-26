// Clean-room bounded GBBS five-cycle profile; see package LICENSE.txt.
package gbbs_five_cycle_count

import "core:c"

MAX_N :: 16
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
gbbs_five_cycle_count :: proc "c" (input: [^]i64, length: c.size_t,
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
    if output == nil || capacity < 8 do return -2

    count: i64 = 0
    for start := 0; start < n; start += 1 {
        for first := start + 1; first < n; first += 1 {
            for second := start + 1; second < n; second += 1 {
                if second == first do continue
                for third := start + 1; third < n; third += 1 {
                    if third == first || third == second do continue
                    for last := first + 1; last < n; last += 1 {
                        if last == second || last == third do continue
                        if adjacent[start][first] && adjacent[first][second] &&
                            adjacent[second][third] && adjacent[third][last] &&
                            adjacent[last][start] do count += 1
                    }
                }
            }
        }
    }
    store_i64_le(output, count)
    return 8
}
