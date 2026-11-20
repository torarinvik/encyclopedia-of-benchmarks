package undirected_eulerian_trail_hierholzer

import "core:c"

@(export)
undirected_eulerian_trail_hierholzer :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 67 do return -1
    if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 32 do return -1
    n := int(input[0]); m := int(input[1])
    if int(length) != 2 + 2 * m do return -1
    endpoints: [32][2]int
    adjacency: [16][64]int
    degree: [16]int
    cursor: [16]int
    for e := 0; e < m; e += 1 {
        u0 := input[2 + 2*e]; v0 := input[3 + 2*e]
        if u0 < 0 || v0 < 0 || u0 >= i64(n) || v0 >= i64(n) do return -1
        u := int(u0); v := int(v0)
        endpoints[e] = {u, v}
        adjacency[u][degree[u]] = e; degree[u] += 1
        adjacency[v][degree[v]] = e; degree[v] += 1
    }
    odd := 0; start := 0
    for v := 0; v < n; v += 1 {
        if degree[v] % 2 != 0 { if odd == 0 do start = v; odd += 1 }
    }
    if odd != 0 && odd != 2 do return 0
    if odd == 0 && m != 0 { for degree[start] == 0 { start += 1 } }
    used: [32]bool
    stack: [33]int
    reverse: [33]int
    top := 1; count := 0; stack[0] = start
    for top != 0 {
        v := stack[top - 1]
        for cursor[v] < degree[v] && used[adjacency[v][cursor[v]]] { cursor[v] += 1 }
        if cursor[v] == degree[v] {
            top -= 1; reverse[count] = stack[top]; count += 1
        } else {
            e := adjacency[v][cursor[v]]; cursor[v] += 1; used[e] = true
            if endpoints[e][0] == v { stack[top] = endpoints[e][1] } else { stack[top] = endpoints[e][0] }
            top += 1
        }
    }
    if count != m + 1 do return 0
    bytes := count * 8
    if output == nil || capacity < c.size_t(bytes) do return -2
    for i := 0; i < count; i += 1 {
        value := u64(reverse[count - 1 - i])
        for b := 0; b < 8; b += 1 { output[8*i+b] = u8((value >> u64(8*b)) & 255) }
    }
    return i64(bytes)
}
