package chordal_graph_recognition
import "core:c"

N :: 6
MAX_INPUT :: 32
MAX_OUTPUT :: 64

put_u64 :: proc(out: [^]u8, index: int, value: u64) {
    bits := value
    for byte := 0; byte < 8; byte += 1 { out[index*8+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
chordal_graph_recognition :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT || input[0] < 1 || input[0] > N || input[1] < 0 || input[1] > 15 { return -1 }
    n, m := int(input[0]), int(input[1])
    if m > n*(n-1)/2 || length != c.size_t(2+2*m) { return -1 }
    adjacent: [N*N]bool
    for e := 0; e < m; e += 1 {
        a0, b0 := input[2+2*e], input[3+2*e]
        if a0 < 0 || b0 < 0 || a0 >= i64(n) || b0 >= i64(n) || a0 == b0 { return -1 }
        a, b := int(a0), int(b0)
        if adjacent[a*N+b] { return -1 }
        adjacent[a*N+b] = true; adjacent[b*N+a] = true
    }
    selected: [N]bool
    label, reverse_order, order, position: [N]int
    for step := 0; step < n; step += 1 {
        chosen := -1
        for v := 0; v < n; v += 1 { if !selected[v] && (chosen < 0 || label[v] > label[chosen]) { chosen = v } }
        selected[chosen] = true; reverse_order[step] = chosen
        for u := 0; u < n; u += 1 { if !selected[u] && adjacent[chosen*N+u] { label[u] += 1 } }
    }
    for i := 0; i < n; i += 1 { order[i] = reverse_order[n-i-1]; position[order[i]] = i }
    peo := true
    for i := 0; i < n && peo; i += 1 {
        v := order[i]
        parent := -1
        for u := 0; u < n; u += 1 { if adjacent[v*N+u] && position[u] > i && (parent < 0 || position[u] < position[parent]) { parent = u } }
        if parent >= 0 { for u := 0; u < n; u += 1 { if adjacent[v*N+u] && position[u] > i && u != parent && !adjacent[parent*N+u] { peo = false } } }
    }
    packed: [8]u64
    count := 0
    if peo {
        packed[count] = 1; count += 1
        for i := 0; i < n; i += 1 { packed[count] = u64(order[i]); count += 1 }
    } else {
        found := false
        cycle: [N]int
        cycle_len := 0
        for mask := 0; mask < (1 << n) && !found; mask += 1 {
            vertices: [N]int
            size := 0
            for v := 0; v < n; v += 1 { if (mask & (1 << v)) != 0 { vertices[size] = v; size += 1 } }
            if size < 4 { continue }
            valid := true
            for i := 0; i < size; i += 1 {
                degree := 0
                for j := 0; j < size; j += 1 { if adjacent[vertices[i]*N+vertices[j]] { degree += 1 } }
                if degree != 2 { valid = false }
            }
            if !valid { continue }
            seen: [N]bool
            queue: [N]int
            head, tail := 0, 1
            seen[vertices[0]] = true; queue[0] = vertices[0]
            for head < tail {
                v := queue[head]; head += 1
                for j := 0; j < size; j += 1 { u := vertices[j]; if adjacent[v*N+u] && !seen[u] { seen[u] = true; queue[tail] = u; tail += 1 } }
            }
            if tail != size { continue }
            cycle_len = size
            start := vertices[0]
            previous, current := start, start
            for j := 0; j < size; j += 1 { if adjacent[start*N+vertices[j]] { current = vertices[j]; break } }
            cycle[0] = start
            for i := 1; i < size; i += 1 {
                cycle[i] = current
                next := start
                for j := 0; j < size; j += 1 { u := vertices[j]; if adjacent[current*N+u] && u != previous { next = u; break } }
                previous, current = current, next
            }
            found = true
        }
        if !found { return -1 }
        packed[count] = 0; count += 1; packed[count] = u64(cycle_len); count += 1
        for i := 0; i < cycle_len; i += 1 { packed[count] = u64(cycle[i]); count += 1 }
    }
    bytes := count*8
    if output == nil || capacity < c.size_t(bytes) { return -2 }
    staged: [MAX_OUTPUT]u8
    for i := 0; i < count; i += 1 { put_u64(&staged[0], i, packed[i]) }
    for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
    return i64(bytes)
}
