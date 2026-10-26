// Clean-room bounded GBBS MPX low-diameter decomposition profile.
package gbbs_low_diameter_decomposition

import "core:c"

N :: 12
M :: 24
MAX_INPUT :: 2 + 2 * M
BATCH :: [13]int{1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11}

@(export)
gbbs_low_diameter_decomposition :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > N || m64 < 0 || m64 > M ||
        length != c.size_t(2 + 2*m64) do return -1
    n, m := int(n64), int(m64)
    adjacent: [N][N]bool = {}
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[2+2*edge], input[3+2*edge]
        if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if adjacent[u][v] do return -1
        adjacent[u][v], adjacent[v][u] = true, true
    }
    if output == nil || capacity < c.size_t(n) do return -2

    label: [N]int = {}
    frontier: [N]int = {}
    for v := 0; v < n; v += 1 do label[v] = -1
    frontier_count, cursor, assigned, round := 0, 0, 0, 0
    for assigned < n {
        end := min(cursor+BATCH[round], n)
        for candidate := cursor; candidate < end; candidate += 1 {
            if label[candidate] < 0 {
                label[candidate] = candidate
                frontier[frontier_count] = candidate
                frontier_count += 1
                assigned += 1
            }
        }
        cursor = end
        if assigned == n do break

        reached: [N]int = {}
        for v := 0; v < n; v += 1 do reached[v] = -1
        for i := 0; i < frontier_count; i += 1 {
            vertex := frontier[i]
            for neighbor := 0; neighbor < n; neighbor += 1 {
                if adjacent[vertex][neighbor] && label[neighbor] < 0 &&
                    (reached[neighbor] < 0 || label[vertex] < reached[neighbor]) {
                    reached[neighbor] = label[vertex]
                }
            }
        }
        frontier_count = 0
        for vertex := 0; vertex < n; vertex += 1 {
            if reached[vertex] >= 0 {
                label[vertex] = reached[vertex]
                frontier[frontier_count] = vertex
                frontier_count += 1
                assigned += 1
            }
        }
        round += 1
    }
    for vertex := 0; vertex < n; vertex += 1 do output[vertex] = u8(label[vertex])
    return i64(n)
}
