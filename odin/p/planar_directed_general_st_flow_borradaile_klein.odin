package planar_directed_general_st_flow_borradaile_klein

import "core:c"

N :: 6
M :: 10
D :: 20
F :: 10
MAX_INPUT :: 61
MAX_AUG :: 25
INF :: i64(0x3fffffffffffffff)

Graph :: struct {
    n, m, source, sink: int,
    tail, head, cap: [M]int,
    degree: [N]int,
    rotation: [N][N]int,
    pos: [N][M]int,
    left_face, right_face: [D]int,
    faces, infinity, root_anchor: int,
}

dart_head :: proc(g: ^Graph, dart: int) -> int {
    e := dart / 2
    if (dart & 1) == 0 do return g.head[e]
    return g.tail[e]
}

left_successor :: proc(g: ^Graph, dart: int) -> int {
    vertex := dart_head(g, dart)
    edge := dart / 2
    degree := g.degree[vertex]
    position := g.pos[vertex][edge]
    if degree <= 0 || position < 0 do return -1
    prior := g.rotation[vertex][(position + degree - 1) % degree]
    return 2 * prior + int(g.head[prior] == vertex)
}

parse :: proc(input: [^]i64, length: c.size_t, g: ^Graph) -> bool {
    if input == nil || length < 4 || length > c.size_t(MAX_INPUT) do return false
    n0, m0, s0, t0 := input[0], input[1], input[2], input[3]
    if n0 < 2 || n0 > N || m0 < 1 || m0 > M || s0 < 0 || s0 >= n0 || t0 < 0 || t0 >= n0 || s0 == t0 do return false
    g.n, g.m, g.source, g.sink = int(n0), int(m0), int(s0), int(t0)
    if length < c.size_t(4 + 3 * g.m) do return false
    pairs: [N][N]bool
    at: c.size_t = 4
    for e := 0; e < g.m; e += 1 {
        u0, v0, c0 := input[at], input[at+1], input[at+2]
        at += 3
        if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || c0 < 1 || c0 > 5 do return false
        u, v := int(u0), int(v0)
        if pairs[u][v] || pairs[v][u] do return false
        pairs[u][v], pairs[v][u] = true, true
        g.tail[e], g.head[e], g.cap[e] = u, v, int(c0)
    }
    occurrence: [M][2]int
    used: [N][M]bool
    for x := 0; x < g.n; x += 1 { for e := 0; e < g.m; e += 1 { g.pos[x][e] = -1 } }
    for x := 0; x < g.n; x += 1 {
        if at >= length do return false
        d0 := input[at]; at += 1
        if d0 < 1 || d0 >= n0 || at + c.size_t(d0) > length do return false
        g.degree[x] = int(d0)
        for j := 0; j < g.degree[x]; j += 1 {
            e0 := input[at]; at += 1
            if e0 < 0 || e0 >= m0 do return false
            e := int(e0)
            if used[x][e] do return false
            used[x][e] = true
            g.rotation[x][j], g.pos[x][e] = e, j
            if g.tail[e] == x { occurrence[e][0] += 1 }
            else if g.head[e] == x { occurrence[e][1] += 1 }
            else { return false }
        }
    }
    if at != length do return false
    for e := 0; e < g.m; e += 1 {
        if occurrence[e][0] != 1 || occurrence[e][1] != 1 do return false
    }

    adjacent: [N][N]bool
    for e := 0; e < g.m; e += 1 { adjacent[g.tail[e]][g.head[e]] = true; adjacent[g.head[e]][g.tail[e]] = true }
    reached: [N]bool
    queue: [N]int
    qh, qt := 0, 1
    reached[g.source], queue[0] = true, g.source
    for qh < qt {
        x := queue[qh]; qh += 1
        for y := 0; y < g.n; y += 1 {
            if adjacent[x][y] && !reached[y] { reached[y], queue[qt] = true, y; qt += 1 }
        }
    }
    for x := 0; x < g.n; x += 1 { if !reached[x] do return false }

    for d := 0; d < 2*g.m; d += 1 { g.left_face[d] = -1 }
    g.faces = 0
    for start := 0; start < 2*g.m; start += 1 {
        if g.left_face[start] >= 0 do continue
        dart := start
        for g.left_face[dart] < 0 {
            g.left_face[dart] = g.faces
            dart = left_successor(g, dart)
            if dart < 0 do return false
        }
        if dart != start do return false
        g.faces += 1
    }
    if g.faces != g.m - g.n + 2 do return false
    for d := 0; d < 2*g.m; d += 1 { g.right_face[d] = g.left_face[d^1] }
    g.root_anchor = g.rotation[g.sink][0]
    root_dart := 2*g.root_anchor + int(g.head[g.root_anchor] == g.sink)
    g.infinity = g.right_face[root_dart]
    return true
}

visit :: proc(g: ^Graph, vertex, anchor: int, root: bool, residual: ^[N][N]int,
    seen: ^[N]bool, parent: ^[N]int) {
    degree := g.degree[vertex]
    position := g.pos[vertex][anchor]
    first := 1
    if root do first = 0
    for step := first; step < first+degree; step += 1 {
        edge := g.rotation[vertex][(position+step)%degree]
        neighbor := g.tail[edge]
        if neighbor == vertex do neighbor = g.head[edge]
        if !seen[neighbor] && residual[neighbor][vertex] > 0 {
            seen[neighbor] = true
            parent[neighbor] = vertex
            visit(g, neighbor, edge, false, residual, seen, parent)
        }
    }
}

solve :: proc(g: ^Graph) -> i64 {
    dual: [F][F]i64
    distance: [F]i64
    settled: [F]bool
    for f := 0; f < F; f += 1 { distance[f] = INF; for h := 0; h < F; h += 1 { dual[f][h] = INF } }
    for d := 0; d < 2*g.m; d += 1 {
        from, to := g.right_face[d], g.left_face[d]
        weight := i64(0)
        if (d & 1) == 0 do weight = i64(g.cap[d/2])
        if weight < dual[from][to] do dual[from][to] = weight
    }
    distance[g.infinity] = 0
    for count := 0; count < g.faces; count += 1 {
        current := -1
        for f := 0; f < g.faces; f += 1 { if !settled[f] && (current < 0 || distance[f] < distance[current]) do current = f }
        if current < 0 || distance[current] == INF do break
        settled[current] = true
        for next := 0; next < g.faces; next += 1 {
            if dual[current][next] != INF && distance[current]+dual[current][next] < distance[next] do distance[next] = distance[current]+dual[current][next]
        }
    }
    residual: [N][N]int
    for e := 0; e < g.m; e += 1 {
        eta := distance[g.left_face[2*e]] - distance[g.right_face[2*e]]
        if eta < 0 || eta > i64(g.cap[e]) do return -1
        residual[g.tail[e]][g.head[e]] += g.cap[e] - int(eta)
        residual[g.head[e]][g.tail[e]] += int(eta)
    }
    total: i64 = 0
    for augmentation := 0; augmentation <= MAX_AUG; augmentation += 1 {
        seen: [N]bool
        parent: [N]int
        for x := 0; x < g.n; x += 1 { parent[x] = -1 }
        seen[g.sink] = true
        visit(g, g.sink, g.root_anchor, true, &residual, &seen, &parent)
        if !seen[g.source] do return total
        if augmentation == MAX_AUG do return -1
        delta := 1 << 30
        x := g.source
        for x != g.sink { y := parent[x]; if residual[x][y] < delta do delta = residual[x][y]; x = y }
        x = g.source
        for x != g.sink { y := parent[x]; residual[x][y] -= delta; residual[y][x] += delta; x = y }
        total += i64(delta)
    }
    return -1
}

@(export)
planar_directed_general_st_flow_borradaile_klein :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    graph: Graph
    if !parse(input, length, &graph) do return -1
    value := solve(&graph)
    if value < 0 do return -1
    if output == nil || capacity < 8 do return -2
    bits := u64(value)
    for i := 0; i < 8; i += 1 { output[i] = u8((bits >> (8*i)) & 255) }
    return 8
}
