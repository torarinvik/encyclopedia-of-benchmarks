// Independently authored draft; not compiled or run.
struct KsGraph {
    n int
    m int
    q int
    mut:
    position int
    left [32]int
    right [32]int
    tape [64]i64
}
fn ks_root(parent [12]int, vertex int) int {
    mut current := vertex
    for parent[current] != current { current = parent[current] }
    return current
}
fn ks_solve(mut g KsGraph, parent [12]int, components int) int {
    if components <= 6 {
        mut index := [12]int{}
        mut count := 0
        for i in 0 .. g.n { if parent[i] == i { index[i] = count; count++ } }
        mut best := g.m + 1
        for mask in 0 .. ((1 << (components-1))-1) {
            side := (mask << 1) | 1
            mut cut := 0
            for e in 0 .. g.m {
                a := index[ks_root(parent, g.left[e])]
                b := index[ks_root(parent, g.right[e])]
                if ((side >> a) & 1) != ((side >> b) & 1) { cut++ }
            }
            if cut < best { best = cut }
        }
        return best
    }
    targets := [0,0,0,0,0,0,0,6,7,8,9,9,10]!
    mut best := g.m + 1
    for branch in 0 .. 2 {
        mut next := parent
        mut remaining := components
        for remaining > targets[components] {
            mut live := 0
            for e in 0 .. g.m { if ks_root(next, g.left[e]) != ks_root(next, g.right[e]) { live++ } }
            if g.position >= g.q { return -1 }
            mut rank := g.tape[g.position]
            g.position++
            if rank < 0 || rank >= i64(live) { return -1 }
            for e in 0 .. g.m {
                a := ks_root(next, g.left[e])
                b := ks_root(next, g.right[e])
                if a == b { continue }
                if rank == 0 { next[b] = a; break }
                rank--
            }
            remaining--
        }
        value := ks_solve(mut g, next, targets[components])
        if value < 0 { return -1 }
        if value < best { best = value }
    }
    return best
}
@[export: 'karger_stein_recursive_contraction']
pub fn karger_stein_recursive_contraction(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < 3 || length > 132 { return -1 }
        if input[0] < 2 || input[0] > 12 || input[1] < 1 || input[1] > 32 || input[2] < 0 || input[2] > 64 { return -1 }
        n := int(input[0]); m := int(input[1]); q := int(input[2])
        if length != usize(3+2*m+q) { return -1 }
        mut g := KsGraph{n:n, m:m, q:q}
        mut parent := [12]int{}
        for i in 0 .. n { parent[i] = i }
        for i in 0 .. m {
            u := input[3+2*i]; v := input[4+2*i]
            if u < 0 || v < 0 || u >= i64(n) || v >= i64(n) || u == v { return -1 }
            g.left[i] = int(u); g.right[i] = int(v)
            a := ks_root(parent, int(u)); b := ks_root(parent, int(v))
            parent[b] = a
        }
        initial := ks_root(parent, 0)
        for i in 1 .. n { if ks_root(parent, i) != initial { return -1 } }
        for i in 0 .. n { parent[i] = i }
        for i in 0 .. q { g.tape[i] = input[3+2*m+i] }
        value := ks_solve(mut g, parent, n)
        if value < 0 || g.position != q { return -1 }
        return i64(value)
    }
}
