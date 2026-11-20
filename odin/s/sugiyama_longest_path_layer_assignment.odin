package sugiyama_longest_path_layer_assignment

import "core:c"

MAX_N :: 32
MAX_M :: 128
MAX_INPUT :: 258

@(export)
sugiyama_longest_path_layer_assignment :: proc "c" (input: [^]i64,
    length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT + 1 do return -1
    n64, m64 := input[0], input[1]
    if n64 < 0 || n64 > 32 || m64 < 0 || m64 > 128 do return -1
    n, m := int(n64), int(m64)
    if length != c.size_t(2 + 2*m) do return -1

    adjacency: [MAX_N]u32
    for edge := 0; edge < m; edge += 1 {
        source, target := input[2+2*edge], input[3+2*edge]
        if source < 0 || source >= n64 || target < 0 || target >= n64 do return -1
        bit := u32(1) << u32(target)
        if adjacency[int(source)] & bit != 0 do return -1
        adjacency[int(source)] |= bit
    }

    removed: [MAX_N]bool
    sink_depth: [MAX_N]int
    remaining, depth := n, 0
    for remaining > 0 {
        sinks: [MAX_N]bool
        sink_count := 0
        for vertex := 0; vertex < n; vertex += 1 {
            if removed[vertex] do continue
            has_successor := false
            for target := 0; target < n; target += 1 {
                if !removed[target] && (adjacency[vertex] & (u32(1) << u32(target))) != 0 {
                    has_successor = true
                    break
                }
            }
            if !has_successor { sinks[vertex] = true; sink_count += 1 }
        }
        if sink_count == 0 do return -1
        for vertex := 0; vertex < n; vertex += 1 {
            if sinks[vertex] { removed[vertex] = true; sink_depth[vertex] = depth }
        }
        remaining -= sink_count
        depth += 1
    }

    output_bytes := 8 * (n + 1)
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    values: [MAX_N+1]u64
    values[0] = u64(depth)
    for vertex := 0; vertex < n; vertex += 1 { values[vertex+1] = u64(depth - 1 - sink_depth[vertex]) }
    for word := 0; word < n + 1; word += 1 {
        for byte := 0; byte < 8; byte += 1 {
            output[word*8+byte] = u8(values[word] >> u64(8*byte))
        }
    }
    return i64(output_bytes)
}
