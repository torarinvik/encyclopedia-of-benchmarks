// Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt.
package gbbs_yoshida_query_mis

import "core:c"

MAX_N :: 12
MAX_M :: 24
MAX_INPUT :: 52
MAX_CUTOFF :: 128

hash64 :: proc(value: u64) -> u64 {
    mixed := value * 3935559000370003845 + 2691343689449507681
    mixed = mixed ~ (mixed >> 21)
    mixed = mixed ~ (mixed << 37)
    mixed = mixed ~ (mixed >> 4)
    mixed *= 4768777513237032717
    mixed = mixed ~ (mixed << 20)
    mixed = mixed ~ (mixed >> 41)
    mixed = mixed ~ (mixed << 5)
    return mixed
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

query :: proc(vertex: int, degree: [^]int, neighbors: [^]int,
               priority: [^]u64, work: [^]int, cutoff: int) -> i64 {
    for index := 0; index < degree[vertex]; index += 1 {
        if work[0] == cutoff do return -1
        neighbor := neighbors[vertex*MAX_N+index]
        work[0] += 1
        if priority[vertex] < priority[neighbor] ||
            (priority[vertex] == priority[neighbor] && vertex <= neighbor) do break
        status := query(neighbor, degree, neighbors, priority, work, cutoff)
        if status == 1 do return 0
        if status == -1 do return -1
    }
    return 1
}

@(export)
gbbs_yoshida_query_mis :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT do return -1
    n64, m64, root64, cutoff64 := input[0], input[1], input[2], input[3]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || root64 < 0 || root64 >= n64 ||
        cutoff64 < 0 || cutoff64 > MAX_CUTOFF || length != c.size_t(4+2*m64) do return -1
    n, m := int(n64), int(m64)
    adjacent: [MAX_N*MAX_N]bool = {}
    degree: [MAX_N]int = {}
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[4+2*edge], input[5+2*edge]
        if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if adjacent[u*MAX_N+v] do return -1
        adjacent[u*MAX_N+v], adjacent[v*MAX_N+u] = true, true
        degree[u] += 1
        degree[v] += 1
    }
    if output == nil || capacity < 16 do return -2
    priority: [MAX_N]u64 = {}
    neighbors: [MAX_N*MAX_N]int = {}
    for vertex := 0; vertex < n; vertex += 1 do priority[vertex] = hash64(u64(vertex))
    for vertex := 0; vertex < n; vertex += 1 {
        inserted := 0
        for other := 0; other < n; other += 1 {
            if adjacent[vertex*MAX_N+other] {
                position := inserted
                for position > 0 {
                    previous := neighbors[vertex*MAX_N+position-1]
                    if priority[previous] < priority[other] ||
                        (priority[previous] == priority[other] && previous < other) do break
                    neighbors[vertex*MAX_N+position] = previous
                    position -= 1
                }
                neighbors[vertex*MAX_N+position] = other
                inserted += 1
            }
        }
    }
    work := 0
    status := query(int(root64), &degree[0], &neighbors[0], &priority[0], &work, int(cutoff64))
    store_i64_le(output, 0, status)
    store_i64_le(output, 8, i64(work))
    return 16
}
