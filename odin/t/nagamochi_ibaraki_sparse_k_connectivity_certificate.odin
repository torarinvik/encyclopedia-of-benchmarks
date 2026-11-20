package nagamochi_ibaraki_sparse_k_connectivity_certificate
import "core:c"

MAX_N :: 8
MAX_M :: 28
MAX_INPUT :: 60

put :: proc(out: [^]u8, at: int, value: i64) {
    bits := u64(value)
    for i := 0; i < 8; i += 1 { out[at+i] = u8(bits & 255); bits >>= 8 }
}

@(export)
nagamochi_ibaraki_sparse_k_connectivity_certificate :: proc "c"(
    input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_INPUT do return -1
    n64, m64, k64 := input[0], input[1], input[2]
    if n64 < 3 || n64 > 8 || m64 < 0 || m64 > 28 || k64 < 1 || k64 > 3 do return -1
    if length != c.size_t(3 + 2*m64) do return -1
    n, m, k := int(n64), int(m64), int(k64)
    u: [MAX_M]int
    v: [MAX_M]int
    incident: [MAX_N * MAX_N]int
    degree: [MAX_N]int
    for e := 0; e < m; e += 1 {
        a, b := input[3+2*e], input[4+2*e]
        if a < 0 || a >= b || b >= n64 do return -1
        u[e], v[e] = int(a), int(b)
        for prior := 0; prior < e; prior += 1 {
            if u[prior] == u[e] && v[prior] == v[e] do return -1
        }
        incident[u[e]*MAX_N+degree[u[e]]] = e
        degree[u[e]] += 1
        incident[v[e]*MAX_N+degree[v[e]]] = e
        degree[v[e]] += 1
    }
    bytes := 8 * (m + 1)
    if output == nil || capacity < c.size_t(bytes) do return -2

    rank: [MAX_N]int
    layer: [MAX_M]int
    scanned_vertex: [MAX_N]bool
    scanned_edge: [MAX_M]bool
    for step := 0; step < n; step += 1 {
        x := n
        for vertex := 0; vertex < n; vertex += 1 {
            if !scanned_vertex[vertex] && (x == n || rank[vertex] > rank[x]) { x = vertex }
        }
        for slot := 0; slot < degree[x]; slot += 1 {
            e := incident[x*MAX_N+slot]
            if scanned_edge[e] do continue
            y := u[e]
            if y == x { y = v[e] }
            layer[e] = rank[y] + 1
            if rank[x] == rank[y] { rank[x] += 1 }
            rank[y] += 1
            scanned_edge[e] = true
        }
        scanned_vertex[x] = true
    }
    put(output, 0, i64(m))
    for e := 0; e < m; e += 1 {
        visible := layer[e]
        if visible > k { visible = 0 }
        put(output, 8*(e+1), i64(visible))
    }
    return i64(bytes)
}
