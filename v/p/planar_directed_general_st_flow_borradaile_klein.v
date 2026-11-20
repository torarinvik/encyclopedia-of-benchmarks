module planar_directed_general_st_flow_borradaile_klein

const (
    max_n = 6
    max_m = 10
    max_darts = 20
    max_faces = 10
    max_input = 61
    max_aug = 25
    inf_dist = i64(0x3fffffffffffffff)
)

struct Graph {
mut:
    n int
    m int
    source int
    sink int
    tail [max_m]int
    head [max_m]int
    cap [max_m]int
    degree [max_n]int
    rotation [max_n][max_n]int
    pos [max_n][max_m]int
    left_face [max_darts]int
    right_face [max_darts]int
    faces int
    infinity int
    root_anchor int
}

fn dart_head(g &Graph, dart int) int {
    e := dart / 2
    return if dart % 2 == 0 { g.head[e] } else { g.tail[e] }
}

fn left_successor(g &Graph, dart int) int {
    vertex := dart_head(g, dart)
    edge := dart / 2
    degree := g.degree[vertex]
    position := g.pos[vertex][edge]
    if degree <= 0 || position < 0 { return -1 }
    prior := g.rotation[vertex][(position + degree - 1) % degree]
    return 2 * prior + if g.head[prior] == vertex { 1 } else { 0 }
}

fn decode(input &i64, length int) ?Graph {
    unsafe {
        if isnil(input) || length < 4 || length > max_input { return none }
        n0, m0, s0, t0 := input[0], input[1], input[2], input[3]
        if n0 < 2 || n0 > max_n || m0 < 1 || m0 > max_m || s0 < 0 || s0 >= n0 || t0 < 0 || t0 >= n0 || s0 == t0 { return none }
        mut g := Graph{n: int(n0), m: int(m0), source: int(s0), sink: int(t0)}
        if length < 4 + 3 * g.m { return none }
        mut pairs := [max_n][max_n]bool{}
        mut at := 4
        for e in 0 .. g.m {
            u0, v0, c0 := input[at], input[at + 1], input[at + 2]
            at += 3
            if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || c0 < 1 || c0 > 5 { return none }
            u, v := int(u0), int(v0)
            if pairs[u][v] || pairs[v][u] { return none }
            pairs[u][v], pairs[v][u] = true, true
            g.tail[e], g.head[e], g.cap[e] = u, v, int(c0)
        }
        mut occurrence := [max_m][2]int{}
        mut used := [max_n][max_m]bool{}
        for x in 0 .. g.n { for e in 0 .. g.m { g.pos[x][e] = -1 } }
        for x in 0 .. g.n {
            if at >= length { return none }
            d0 := input[at]
            at++
            if d0 < 1 || d0 >= n0 || at + int(d0) > length { return none }
            g.degree[x] = int(d0)
            for j in 0 .. g.degree[x] {
                e0 := input[at]
                at++
                if e0 < 0 || e0 >= m0 { return none }
                e := int(e0)
                if used[x][e] { return none }
                used[x][e] = true
                g.rotation[x][j], g.pos[x][e] = e, j
                if g.tail[e] == x { occurrence[e][0]++ } else if g.head[e] == x { occurrence[e][1]++ } else { return none }
            }
        }
        if at != length { return none }
        for e in 0 .. g.m { if occurrence[e][0] != 1 || occurrence[e][1] != 1 { return none } }

        mut adjacent := [max_n][max_n]bool{}
        for e in 0 .. g.m { adjacent[g.tail[e]][g.head[e]] = true; adjacent[g.head[e]][g.tail[e]] = true }
        mut seen := [max_n]bool{}
        mut queue := [max_n]int{}
        mut qh, qt := 0, 1
        seen[g.source], queue[0] = true, g.source
        for qh < qt {
            x := queue[qh]
            qh++
            for y in 0 .. g.n { if adjacent[x][y] && !seen[y] { seen[y], queue[qt] = true, y; qt++ } }
        }
        for x in 0 .. g.n { if !seen[x] { return none } }

        for d in 0 .. 2 * g.m { g.left_face[d] = -1 }
        g.faces = 0
        for start in 0 .. 2 * g.m {
            if g.left_face[start] >= 0 { continue }
            mut dart := start
            for g.left_face[dart] < 0 {
                g.left_face[dart] = g.faces
                dart = left_successor(&g, dart)
                if dart < 0 { return none }
            }
            if dart != start { return none }
            g.faces++
        }
        if g.faces != g.m - g.n + 2 { return none }
        for d in 0 .. 2 * g.m { g.right_face[d] = g.left_face[d ^ 1] }
        g.root_anchor = g.rotation[g.sink][0]
        root_dart := 2 * g.root_anchor + if g.head[g.root_anchor] == g.sink { 1 } else { 0 }
        g.infinity = g.right_face[root_dart]
        return g
    }
}

fn right_first(g &Graph, vertex int, anchor int, root bool, residual & [max_n][max_n]int, mut seen [max_n]bool, mut parent [max_n]int) {
    degree := g.degree[vertex]
    position := g.pos[vertex][anchor]
    first := if root { 0 } else { 1 }
    for step := first; step < first + degree; step++ {
        edge := g.rotation[vertex][(position + step) % degree]
        neighbor := if g.tail[edge] == vertex { g.head[edge] } else { g.tail[edge] }
        if !seen[neighbor] && residual[neighbor][vertex] > 0 {
            seen[neighbor] = true
            parent[neighbor] = vertex
            right_first(g, neighbor, edge, false, residual, mut seen, mut parent)
        }
    }
}

fn solve(g &Graph) i64 {
    mut dual := [max_faces][max_faces]i64{}
    mut distance := [max_faces]i64{}
    mut settled := [max_faces]bool{}
    for f in 0 .. max_faces { distance[f] = inf_dist; for h in 0 .. max_faces { dual[f][h] = inf_dist } }
    for d in 0 .. 2 * g.m {
        from, to := g.right_face[d], g.left_face[d]
        weight := if d % 2 == 0 { i64(g.cap[d / 2]) } else { i64(0) }
        if weight < dual[from][to] { dual[from][to] = weight }
    }
    distance[g.infinity] = 0
    for _ in 0 .. g.faces {
        mut current := -1
        for f in 0 .. g.faces { if !settled[f] && (current < 0 || distance[f] < distance[current]) { current = f } }
        if current < 0 || distance[current] == inf_dist { break }
        settled[current] = true
        for next in 0 .. g.faces { if dual[current][next] != inf_dist && distance[current] + dual[current][next] < distance[next] { distance[next] = distance[current] + dual[current][next] } }
    }
    mut residual := [max_n][max_n]int{}
    for e in 0 .. g.m {
        eta := distance[g.left_face[2 * e]] - distance[g.right_face[2 * e]]
        if eta < 0 || eta > g.cap[e] { return -1 }
        residual[g.tail[e]][g.head[e]] += g.cap[e] - int(eta)
        residual[g.head[e]][g.tail[e]] += int(eta)
    }
    mut total := i64(0)
    for augmentation in 0 .. max_aug + 1 {
        mut seen := [max_n]bool{}
        mut parent := [max_n]int{}
        for x in 0 .. g.n { parent[x] = -1 }
        seen[g.sink] = true
        right_first(g, g.sink, g.root_anchor, true, residual, mut seen, mut parent)
        if !seen[g.source] { return total }
        if augmentation == max_aug { return -1 }
        mut delta := 1 << 30
        mut x := g.source
        for x != g.sink { y := parent[x]; if residual[x][y] < delta { delta = residual[x][y] }; x = y }
        x = g.source
        for x != g.sink { y := parent[x]; residual[x][y] -= delta; residual[y][x] += delta; x = y }
        total += i64(delta)
    }
    return -1
}

@[export: 'planar_directed_general_st_flow_borradaile_klein']
pub fn planar_directed_general_st_flow_borradaile_klein(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length < 4 || length > max_input { return -1 }
        graph := decode(input, int(length)) or { return -1 }
        value := solve(&graph)
        if value < 0 { return -1 }
        if isnil(output) || capacity < 8 { return -2 }
        bits := u64(value)
        for i in 0 .. 8 { output[i] = u8((bits >> (8 * i)) & 255) }
        return 8
    }
}
