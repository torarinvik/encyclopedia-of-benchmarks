package fast_minimal_triangulation

import "core:c"

N :: 8
M :: 28
MAX_INPUT :: 59
Graph :: [N]u16

put_word :: proc(output: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[at+byte] = u8(bits & 255); bits >>= 8 }
}

fmt :: proc(vertices: u16, graph: Graph) -> u64 {
    complete := true
    for u := 0; u < N; u += 1 {
        if ((vertices >> u) & 1) != 0 {
            others := vertices & ~(u16(1) << u)
            if graph[u] & others != others { complete = false }
        }
    }
    if complete { return 0 }
    pivot := 0
    for ; pivot < N; pivot += 1 {
        if ((vertices >> pivot) & 1) != 0 {
            others := vertices & ~(u16(1) << pivot)
            if graph[pivot] & others != others { break }
        }
    }
    a := (u16(1) << pivot) | graph[pivot] & vertices
    unseen := vertices & ~a
    components: [N]u16
    closures: [N]u16
    count := 0
    for unseen != 0 {
        seed := 0
        for ; seed < N; seed += 1 { if ((unseen >> seed) & 1) != 0 { break } }
        comp := u16(1) << seed
        unseen &= ~comp
        frontier := comp
        for frontier != 0 {
            u := 0
            for ; u < N; u += 1 { if ((frontier >> u) & 1) != 0 { break } }
            frontier &= ~(u16(1) << u)
            added := graph[u] & unseen
            comp |= added; frontier |= added; unseen &= ~added
        }
        components[count] = comp
        count += 1
    }
    saturated := graph
    result: u64 = 0
    for ci := 0; ci < count; ci += 1 {
        comp := components[ci]
        boundary: u16 = 0
        for u := 0; u < N; u += 1 {
            if ((comp >> u) & 1) != 0 { boundary |= graph[u] & vertices & ~comp }
        }
        closures[ci] = comp | boundary
        for u := 0; u < N; u += 1 {
            if ((boundary >> u) & 1) == 0 { continue }
            for v := u + 1; v < N; v += 1 {
                if ((boundary >> v) & 1) != 0 && ((saturated[u] >> v) & 1) == 0 {
                    saturated[u] |= u16(1) << v; saturated[v] |= u16(1) << u
                    result |= u64(1) << (u*N+v)
                }
            }
        }
    }
    result |= fmt(a, saturated)
    for ci := 0; ci < count; ci += 1 { result |= fmt(closures[ci], saturated) }
    return result
}

@(export)
fast_minimal_triangulation :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > N || m64 < 0 || m64 > M || length != c.size_t(2+2*m64) do return -1
    n, m := int(n64), int(m64)
    graph: Graph
    original: u64 = 0
    previous_u, previous_v: i64 = -1, -1
    for i := 0; i < m; i += 1 {
        u64, v64 := input[2+2*i], input[3+2*i]
        if u64 < 0 || v64 <= u64 || v64 >= n64 || u64 < previous_u || (u64 == previous_u && v64 <= previous_v) do return -1
        previous_u, previous_v = u64, v64
        u, v := int(u64), int(v64)
        graph[u] |= u16(1) << v; graph[v] |= u16(1) << u
        original |= u64(1) << (u*N+v)
    }
    fill := fmt((u16(1)<<n)-1, graph) & ~original
    count := 0
    for u := 0; u < n; u += 1 { for v := u+1; v < n; v += 1 { if ((fill >> (u*N+v)) & 1) != 0 { count += 1 } } }
    bytes := 8*(1+2*count)
    if output == nil || capacity < c.size_t(bytes) do return -2
    put_word(output, 0, i64(count))
    index := 1
    for u := 0; u < n; u += 1 { for v := u+1; v < n; v += 1 {
        if ((fill >> (u*N+v)) & 1) != 0 { put_word(output, 8*index, i64(u)); index += 1; put_word(output, 8*index, i64(v)); index += 1 }
    } }
    return i64(bytes)
}
