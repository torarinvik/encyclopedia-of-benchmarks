// Independently authored draft; not compiled or run.
package karger_stein_recursive_contraction
import "core:c"

Graph :: struct { n, m, q, position: int, left, right: [32]int, tape: [64]i64 }
root :: proc(parent: [12]int, vertex: int) -> int {
    current := vertex
    for parent[current] != current { current = parent[current] }
    return current
}
solve :: proc(g: ^Graph, parent: [12]int, components: int) -> int {
    if components <= 6 {
        index: [12]int
        count := 0
        for i := 0; i < g.n; i += 1 { if parent[i] == i { index[i] = count; count += 1 } }
        best := g.m + 1
        for mask := 0; mask < (1 << uint(components-1))-1; mask += 1 {
            side := (mask << 1) | 1
            cut := 0
            for e := 0; e < g.m; e += 1 {
                a := index[root(parent, g.left[e])]; b := index[root(parent, g.right[e])]
                if ((side >> uint(a)) & 1) != ((side >> uint(b)) & 1) { cut += 1 }
            }
            if cut < best { best = cut }
        }
        return best
    }
    targets := [13]int{0,0,0,0,0,0,0,6,7,8,9,9,10}
    best := g.m + 1
    for branch := 0; branch < 2; branch += 1 {
        next := parent
        for remaining := components; remaining > targets[components]; remaining -= 1 {
            live := 0
            for e := 0; e < g.m; e += 1 { if root(next, g.left[e]) != root(next, g.right[e]) { live += 1 } }
            if g.position >= g.q do return -1
            rank := g.tape[g.position]; g.position += 1
            if rank < 0 || rank >= i64(live) do return -1
            for e := 0; e < g.m; e += 1 {
                a := root(next, g.left[e]); b := root(next, g.right[e])
                if a == b do continue
                if rank == 0 { next[b] = a; break }
                rank -= 1
            }
        }
        value := solve(g, next, targets[components])
        if value < 0 do return -1
        if value < best { best = value }
    }
    return best
}
@(export)
karger_stein_recursive_contraction :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 132 do return -1
    if input[0] < 2 || input[0] > 12 || input[1] < 1 || input[1] > 32 || input[2] < 0 || input[2] > 64 do return -1
    g: Graph
    g.n = int(input[0]); g.m = int(input[1]); g.q = int(input[2])
    if length != c.size_t(3+2*g.m+g.q) do return -1
    parent: [12]int
    for i := 0; i < g.n; i += 1 { parent[i] = i }
    for i := 0; i < g.m; i += 1 {
        u, v := input[3+2*i], input[4+2*i]
        if u < 0 || v < 0 || u >= i64(g.n) || v >= i64(g.n) || u == v do return -1
        g.left[i] = int(u); g.right[i] = int(v)
        a := root(parent, int(u)); b := root(parent, int(v)); parent[b] = a
    }
    initial := root(parent, 0)
    for i := 1; i < g.n; i += 1 { if root(parent, i) != initial do return -1 }
    for i := 0; i < g.n; i += 1 { parent[i] = i }
    for i := 0; i < g.q; i += 1 { g.tape[i] = input[3+2*g.m+i] }
    value := solve(&g, parent, g.n)
    if value < 0 || g.position != g.q do return -1
    return i64(value)
}
