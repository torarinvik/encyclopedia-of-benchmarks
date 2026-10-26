package pannotia_priority_coloring

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 147
MAX_PRIORITY :: i64(99_999_998)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
pannotia_priority_coloring :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    n64, m64, mode64 := input[0], input[1], input[2]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || (mode64 != 0 && mode64 != 1) ||
        length != c.size_t(3+n64+2*m64) do return -1
    n, m, mode := int(n64), int(m64), int(mode64)
    adjacency: [MAX_N]u64
    degree: [MAX_N]int
    priority: [MAX_N]i64
    color: [MAX_N]i64
    active: [MAX_N]bool
    for v := 0; v < n; v += 1 {
        priority[v] = input[3+v]
        if priority[v] < 0 || priority[v] > MAX_PRIORITY do return -1
        for prior := 0; prior < v; prior += 1 do if priority[prior] == priority[v] do return -1
        color[v] = -1
        active[v] = true
    }
    for edge := 0; edge < m; edge += 1 {
        u_value, v_value := input[3+n+2*edge], input[4+n+2*edge]
        if u_value < 0 || v_value <= u_value || v_value >= n64 do return -1
        u, v := int(u_value), int(v_value)
        bit := u64(1) << v
        if adjacency[u] & bit != 0 do return -1
        adjacency[u] |= bit
        adjacency[v] |= u64(1) << u
        degree[u] += 1
        degree[v] += 1
    }
    for v := 0; v < n; v += 1 do if degree[v] == 1 do return -1
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    current_color := i64(1)
    for {
        chosen: [MAX_N]bool
        chosen_count := 0
        for v := 0; v < n; v += 1 {
            if !active[v] do continue
            maximum, minimum := i64(-1), i64(99_999_999)
            for u := 0; u < n; u += 1 if active[u] && adjacency[v] & (u64(1) << u) != 0 {
                if priority[u] > maximum do maximum = priority[u]
                if priority[u] < minimum do minimum = priority[u]
            }
            if priority[v] > maximum { color[v] = current_color; chosen[v] = true }
            if mode == 1 && priority[v] < minimum { color[v] = current_color+1; chosen[v] = true }
            if chosen[v] do chosen_count += 1
        }
        if chosen_count == 0 do return -1
        for v := 0; v < n; v += 1 do if chosen[v] do active[v] = false
        remaining := false
        for v := 0; v < n; v += 1 do remaining = remaining || active[v]
        if !remaining do break
        current_color += if mode == 1 { 2 } else { 1 }
    }
    for v := 0; v < n; v += 1 do store_i64_le(output, 8*v, color[v])
    return i64(output_bytes)
}
