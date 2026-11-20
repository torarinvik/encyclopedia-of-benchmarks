package havel_hakimi_graph_realization

import "core:c"

MAX_N :: 8
MAX_EDGES :: 28
MAX_INPUT :: 10

store_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
havel_hakimi_graph_realization :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT) do return -1
    n_value := input[0]
    if n_value < 0 || n_value > MAX_N do return -1
    n := int(n_value)
    if length != c.size_t(n + 1) do return -1
    residual: [MAX_N]int
    active: [MAX_N]bool
    for v := 0; v < n; v += 1 {
        d := input[v + 1]
        if d < 0 || d >= n_value do return -1
        residual[v] = int(d); active[v] = true
    }
    left: [MAX_EDGES]i64
    right: [MAX_EDGES]i64
    edge_count := 0
    graphical := true
    for graphical {
        hub := -1
        for v := 0; v < n; v += 1 {
            if active[v] && residual[v] > 0 && (hub < 0 || residual[v] > residual[hub] || (residual[v] == residual[hub] && v < hub)) { hub = v }
        }
        if hub < 0 do break
        d := residual[hub]; residual[hub] = 0; active[hub] = false
        candidates: [MAX_N]int
        count := 0
        for v := 0; v < n; v += 1 { if active[v] { candidates[count] = v; count += 1 } }
        for i := 1; i < count; i += 1 {
            value := candidates[i]; j := i
            for j > 0 && (residual[candidates[j - 1]] < residual[value] || (residual[candidates[j - 1]] == residual[value] && candidates[j - 1] > value)) {
                candidates[j] = candidates[j - 1]; j -= 1
            }
            candidates[j] = value
        }
        if d > count { graphical = false; break }
        for i := 0; i < d; i += 1 {
            neighbor := candidates[i]
            if residual[neighbor] == 0 { graphical = false; break }
            residual[neighbor] -= 1
            left[edge_count] = i64(min(hub, neighbor)); right[edge_count] = i64(max(hub, neighbor)); edge_count += 1
        }
    }
    words: [2 + 2 * MAX_EDGES]i64
    used := 0
    if graphical {
        words[0] = 1; words[1] = i64(edge_count); used = 2 + 2 * edge_count
        for i := 0; i < edge_count; i += 1 { words[2 + 2 * i] = left[i]; words[3 + 2 * i] = right[i] }
    } else { words[0] = 0; used = 1 }
    byte_count := used * 8
    if output == nil || capacity < c.size_t(byte_count) do return -2
    for i := 0; i < used; i += 1 { store_i64(output, i * 8, words[i]) }
    return i64(byte_count)
}
