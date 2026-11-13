package karger_contraction_trial

import "core:c"

root :: proc(parent: [8]int, vertex: int) -> int {
    current := vertex
    for parent[current] != current { current = parent[current] }
    return current
}

@(export)
karger_contraction_trial :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 57 do return -1
    if input[0] < 2 || input[0] > 8 || input[1] < 1 || input[1] > 24 do return -1
    n := int(input[0]); m := int(input[1])
    if length != c.size_t(2 + 2*m + n - 2) do return -1
    u, v: [24]int
    parent: [8]int
    for i := 0; i < n; i += 1 { parent[i] = i }
    for i := 0; i < m; i += 1 {
        a := input[2+2*i]; b := input[3+2*i]
        if a < 0 || b < 0 || a >= i64(n) || b >= i64(n) || a == b do return -1
        u[i] = int(a); v[i] = int(b)
        parent[root(parent, u[i])] = root(parent, v[i])
    }
    initial := root(parent, 0)
    for i := 1; i < n; i += 1 { if root(parent, i) != initial do return -1 }
    for i := 0; i < n; i += 1 { parent[i] = i }
    for step := 0; step < n-2; step += 1 {
        live := 0
        for i := 0; i < m; i += 1 { if root(parent, u[i]) != root(parent, v[i]) { live += 1 } }
        rank := input[2+2*m+step]
        if rank < 0 || rank >= i64(live) do return -1
        for i := 0; i < m; i += 1 {
            left := root(parent, u[i]); right := root(parent, v[i])
            if left == right do continue
            if rank == 0 { parent[left] = right; break }
            rank -= 1
        }
    }
    cut := 0
    for i := 0; i < m; i += 1 { if root(parent, u[i]) != root(parent, v[i]) { cut += 1 } }
    return i64(cut)
}
