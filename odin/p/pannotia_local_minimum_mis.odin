package pannotia_local_minimum_mis

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 146
MAX_PRIORITY :: i64(99_999_998)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
pannotia_local_minimum_mis :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != c.size_t(2+n64+2*m64) do return -1
    n, m := int(n64), int(m64)
    adjacency: [MAX_N]u64
    priority: [MAX_N]i64
    for v := 0; v < n; v += 1 {
        priority[v] = input[2+v]
        if priority[v] < 0 || priority[v] > MAX_PRIORITY do return -1
        for prior := 0; prior < v; prior += 1 do if priority[prior] == priority[v] do return -1
    }
    for edge := 0; edge < m; edge += 1 {
        u_value, v_value := input[2+n+2*edge], input[3+n+2*edge]
        if u_value < 0 || v_value <= u_value || v_value >= n64 do return -1
        u, v := int(u_value), int(v_value)
        bit := u64(1) << v
        if adjacency[u] & bit != 0 do return -1
        adjacency[u] |= bit
        adjacency[v] |= u64(1) << u
    }
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    active: [MAX_N]bool
    selected: [MAX_N]bool
    for v := 0; v < n; v += 1 do active[v] = true
    for {
        chosen: [MAX_N]bool
        chosen_count := 0
        for v := 0; v < n; v += 1 {
            if !active[v] do continue
            local_minimum := true
            for u := 0; u < n; u += 1 {
                if active[u] && adjacency[v] & (u64(1) << u) != 0 && priority[u] < priority[v] do local_minimum = false
            }
            if local_minimum { chosen[v] = true; chosen_count += 1 }
        }
        if chosen_count == 0 do return -1
        for v := 0; v < n; v += 1 do if chosen[v] { selected[v] = true; active[v] = false }
        for v := 0; v < n; v += 1 do if chosen[v] {
            for u := 0; u < n; u += 1 do if active[u] && adjacency[v] & (u64(1) << u) != 0 do active[u] = false
        }
        remaining := false
        for v := 0; v < n; v += 1 do remaining = remaining || active[v]
        if !remaining do break
    }
    for v := 0; v < n; v += 1 do store_i64_le(output, 8*v, if selected[v] {2} else {0})
    return i64(output_bytes)
}
