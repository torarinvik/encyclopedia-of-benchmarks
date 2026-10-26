// Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt.
package gapbs_afforest_components

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_SAMPLES :: 64
MAX_INPUT :: 195

link_components :: proc(u, v: int, component: ^[MAX_N]int) {
    p1, p2 := component^[u], component^[v]
    for p1 != p2 {
        high, low := max(p1, p2), min(p1, p2)
        parent_high := component^[high]
        if parent_high == low do break
        if parent_high == high { component^[high] = low; break }
        p1 = component^[component^[high]]
        p2 = component^[low]
    }
}

compress_components :: proc(n: int, component: ^[MAX_N]int) {
    for vertex := 0; vertex < n; vertex += 1 {
        for component^[vertex] != component^[component^[vertex]] {
            component^[vertex] = component^[component^[vertex]]
        }
    }
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gapbs_afforest_components :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT do return -1
    n64, m64, sample_count64 := input[0], input[1], input[2]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || sample_count64 < 1 || sample_count64 > MAX_SAMPLES do return -1
    n, m, sample_count := int(n64), int(m64), int(sample_count64)
    if length != c.size_t(3+sample_count+2*m) do return -1
    samples: [MAX_SAMPLES]int
    for i := 0; i < sample_count; i += 1 {
        sample := input[3+i]
        if sample < 0 || sample >= n64 do return -1
        samples[i] = int(sample)
    }
    adjacency: [MAX_N*MAX_N]bool
    for edge := 0; edge < m; edge += 1 {
        pos := 3+sample_count+2*edge
        u, v := input[pos], input[pos+1]
        if u < 0 || v <= u || v >= n64 || adjacency[int(u)*MAX_N+int(v)] do return -1
        adjacency[int(u)*MAX_N+int(v)] = true
        adjacency[int(v)*MAX_N+int(u)] = true
    }
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    neighbors: [MAX_N*MAX_N]int
    degree: [MAX_N]int
    for u := 0; u < n; u += 1 {
        for v := 0; v < n; v += 1 {
            if adjacency[u*MAX_N+v] { neighbors[u*MAX_N+degree[u]] = v; degree[u] += 1 }
        }
    }
    component: [MAX_N]int
    for vertex := 0; vertex < n; vertex += 1 { component[vertex] = vertex }
    for round := 0; round < 2; round += 1 {
        for u := 0; u < n; u += 1 {
            if degree[u] > round { link_components(u, neighbors[u*MAX_N+round], &component) }
        }
        compress_components(n, &component)
    }
    sample_counts: [MAX_N]int
    for i := 0; i < sample_count; i += 1 { sample_counts[component[samples[i]]] += 1 }
    skip_label := 0
    for label := 1; label < n; label += 1 {
        if sample_counts[label] > sample_counts[skip_label] { skip_label = label }
    }
    skip_is_safe := true
    for u := 0; u < n && skip_is_safe; u += 1 {
        if component[u] != skip_label do continue
        for offset := 2; offset < degree[u]; offset += 1 {
            if component[neighbors[u*MAX_N+offset]] != skip_label { skip_is_safe = false; break }
        }
    }
    for u := 0; u < n; u += 1 {
        if skip_is_safe && component[u] == skip_label do continue
        for offset := 2; offset < degree[u]; offset += 1 {
            link_components(u, neighbors[u*MAX_N+offset], &component)
        }
    }
    compress_components(n, &component)
    for vertex := 0; vertex < n; vertex += 1 { store_i64_le(output, 8*vertex, i64(component[vertex])) }
    return i64(output_bytes)
}
