package ida_star_graph
import "core:c"

Search :: struct {
    n, goal, bound, next: int,
    h: [12]int,
    edges: [12]u16,
}

visit :: proc(s: ^Search, u, depth: int, path: u16) -> int {
    score := depth + s.h[u]
    if score > s.bound {
        if score < s.next do s.next = score
        return -1
    }
    if u == s.goal do return depth
    for v in 0..<s.n {
        bit := u16(1) << u16(v)
        if s.edges[u] & bit != 0 && path & bit == 0 {
            found := visit(s, v, depth + 1, path | bit)
            if found >= 0 do return found
        }
    }
    return -1
}

@(export)
ida_star_graph :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    invalid := i64(-9223372036854775807) - 1
    if values == nil || length < 5 || length > 112 do return invalid
    n0, m0, start0, goal0 := values[0], values[1], values[2], values[3]
    if n0 < 1 || n0 > 12 || m0 < 0 || m0 > 48 || start0 < 0 || start0 >= n0 ||
        goal0 < 0 || goal0 >= n0 || length != c.size_t(4+n0+2*m0) do return invalid
    n, m, start, goal := int(n0), int(m0), int(start0), int(goal0)
    s := Search{n = n, goal = goal}
    for i in 0..<n {
        if values[4+i] < 0 || values[4+i] >= n0 do return invalid
        s.h[i] = int(values[4+i])
    }
    if s.h[goal] != 0 do return invalid
    for i in 0..<m {
        u0, v0 := values[4+n+2*i], values[5+n+2*i]
        if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 do return invalid
        u, v := int(u0), int(v0)
        bit := u16(1) << u16(v)
        if s.edges[u] & bit != 0 || s.h[u] > s.h[v]+1 do return invalid
        s.edges[u] |= bit
    }
    s.bound = s.h[start]
    for {
        s.next = 1000
        found := visit(&s, start, 0, u16(1) << u16(start))
        if found >= 0 do return i64(found)
        if s.next == 1000 do return -1
        s.bound = s.next
    }
}
