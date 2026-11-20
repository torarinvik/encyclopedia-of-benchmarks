package orthogonal_drawing_minimum_bends

import "core:c"

NMAX :: 8
MMAX :: 16
FMAX :: 10
INPUT_MAX :: 79
NODE_MAX :: 20
EDGE_MAX :: 200
INF :: i64(1) << 60

Edge :: struct { from: int, to: int, reverse: int, capacity: i64, cost: i64 }

connected :: proc "contextless" (adj: [NMAX][NMAX]bool, n, removed: int) -> bool {
    start := 0
    if removed == 0 { start = 1 }
    var seen: [NMAX]bool
    var stack: [NMAX]int
    top, count := 1, 0
    seen[start] = true
    stack[0] = start
    for top > 0 {
        top -= 1
        u := stack[top]
        count += 1
        for v := 0; v < n; v += 1 {
            if v != removed && adj[u][v] && !seen[v] {
                seen[v] = true
                stack[top] = v
                top += 1
            }
        }
    }
    expected := n
    if removed >= 0 { expected -= 1 }
    return count == expected
}

add_arc :: proc "contextless" (edges: ^[EDGE_MAX]Edge, count: ^int,
        u, v: int, capacity, cost: i64) -> bool {
    if count^ + 2 > EDGE_MAX { return false }
    e := count^
    edges[e] = Edge{u, v, e + 1, capacity, cost}
    edges[e + 1] = Edge{v, u, e, 0, -cost}
    count^ += 2
    return true
}

@(export)
orthogonal_drawing_minimum_bends :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 4 || input_length > c.size_t(INPUT_MAX) { return -1 }
    n0, m0, f0, outside0 := input[0], input[1], input[2], input[3]
    if n0 < 3 || n0 > NMAX || m0 < n0 || m0 > MMAX || f0 < 2 || f0 > FMAX ||
        f0 != m0 - n0 + 2 || outside0 < 0 || outside0 >= f0 { return -1 }
    n, m, f, outside := int(n0), int(m0), int(f0), int(outside0)
    var adj: [NMAX][NMAX]bool
    var degree: [NMAX]int
    var edge_u, edge_v: [MMAX]int
    var uses: [NMAX][NMAX]int
    cursor := 4
    for e := 0; e < m; e += 1 {
        if cursor + 2 > int(input_length) { return -1 }
        u0, v0 := input[cursor], input[cursor + 1]
        cursor += 2
        if u0 < 0 || u0 >= v0 || v0 >= n0 { return -1 }
        u, v := int(u0), int(v0)
        if adj[u][v] || (e > 0 && (u < edge_u[e - 1] || (u == edge_u[e - 1] && v <= edge_v[e - 1]))) { return -1 }
        adj[u][v], adj[v][u] = true, true
        degree[u] += 1; degree[v] += 1
        edge_u[e], edge_v[e] = u, v
    }
    for v := 0; v < n; v += 1 { if degree[v] < 2 || degree[v] > 4 { return -1 } }
    var faces: [FMAX][NMAX]int
    var width: [FMAX]int
    var link_adj: [NMAX][NMAX][NMAX]bool
    var link_degree: [NMAX][NMAX]int
    for g := 0; g < f; g += 1 {
        if cursor >= int(input_length) { return -1 }
        w0 := input[cursor]; cursor += 1
        if w0 < 3 || w0 > n0 || cursor + int(w0) > int(input_length) { return -1 }
        width[g] = int(w0)
        var row_seen: [NMAX]bool
        for i := 0; i < width[g]; i += 1 {
            x0 := input[cursor]; cursor += 1
            if x0 < 0 || x0 >= n0 { return -1 }
            x := int(x0)
            if row_seen[x] { return -1 }
            row_seen[x] = true; faces[g][i] = x
        }
        for i := 0; i < width[g]; i += 1 {
            u, v := faces[g][i], faces[g][(i + 1) % width[g]]
            if !adj[u][v] { return -1 }
            uses[u][v] += 1
        }
        for i := 0; i < width[g]; i += 1 {
            center := faces[g][i]
            before := faces[g][(i + width[g] - 1) % width[g]]
            after := faces[g][(i + 1) % width[g]]
            if before == after { return -1 }
            link_adj[center][before][after] = true
            link_adj[center][after][before] = true
            link_degree[center][before] += 1
            link_degree[center][after] += 1
        }
    }
    if cursor != int(input_length) || n - m + f != 2 || !connected(adj, n, -1) { return -1 }
    for v := 0; v < n; v += 1 { if !connected(adj, n, v) { return -1 } }
    for e := 0; e < m; e += 1 {
        if uses[edge_u[e]][edge_v[e]] != 1 || uses[edge_v[e]][edge_u[e]] != 1 { return -1 }
    }
    for center := 0; center < n; center += 1 {
        start, incident_count := -1, 0
        for neighbor := 0; neighbor < n; neighbor += 1 {
            if adj[center][neighbor] {
                if link_degree[center][neighbor] != 2 { return -1 }
                if start < 0 { start = neighbor }
                incident_count += 1
            } else if link_degree[center][neighbor] != 0 { return -1 }
        }
        var seen: [NMAX]bool
        var stack: [NMAX]int
        top, reached := 1, 0
        seen[start] = true; stack[0] = start
        for top > 0 {
            top -= 1
            neighbor := stack[top]
            reached += 1
            for other := 0; other < n; other += 1 {
                if link_adj[center][neighbor][other] && !seen[other] {
                    seen[other] = true; stack[top] = other; top += 1
                }
            }
        }
        if reached != incident_count { return -1 }
    }
    var face_a, face_b, face_use: [MMAX]int
    for g := 0; g < f; g += 1 {
        for i := 0; i < width[g]; i += 1 {
            u, v := faces[g][i], faces[g][(i + 1) % width[g]]
            lo, hi := u, v
            if lo > hi { lo, hi = hi, lo }
            found := -1
            for e := 0; e < m; e += 1 { if edge_u[e] == lo && edge_v[e] == hi { found = e; break } }
            if found < 0 || face_use[found] >= 2 { return -1 }
            if face_use[found] == 0 { face_a[found] = g } else { face_b[found] = g }
            face_use[found] += 1
        }
    }
    for e := 0; e < m; e += 1 { if face_use[e] != 2 || face_a[e] == face_b[e] { return -1 } }
    if output == nil || output_capacity < 8 { return -2 }

    base, source := n + f, n + f
    sink, nodes := base + 1, base + 2
    var edges: [EDGE_MAX]Edge
    edge_count := 0
    var balance: [NMAX + FMAX]i64
    for v := 0; v < n; v += 1 { balance[v] = 4 }
    for g := 0; g < f; g += 1 {
        d := i64(width[g])
        balance[n + g] -= 2*d + i64(4)
        if g != outside { balance[n + g] += 8 }
        for i := 0; i < width[g]; i += 1 {
            v := faces[g][i]
            balance[v] -= 1; balance[n + g] += 1
            if !add_arc(&edges, &edge_count, v, n + g, 4*i64(n), 0) { return -1 }
        }
    }
    for e := 0; e < m; e += 1 {
        if !add_arc(&edges, &edge_count, n + face_a[e], n + face_b[e], 4*i64(n), 1) ||
            !add_arc(&edges, &edge_count, n + face_b[e], n + face_a[e], 4*i64(n), 1) { return -1 }
    }
    required: i64 = 0
    for v := 0; v < base; v += 1 {
        if balance[v] > 0 {
            if !add_arc(&edges, &edge_count, source, v, balance[v], 0) { return -1 }
            required += balance[v]
        } else if balance[v] < 0 && !add_arc(&edges, &edge_count, v, sink, -balance[v], 0) { return -1 }
    }
    var potential: [NODE_MAX]i64
    total_flow, total_cost: i64 = 0, 0
    for total_flow < required {
        var dist: [NODE_MAX]i64
        var parent: [NODE_MAX]int
        var used: [NODE_MAX]bool
        for v := 0; v < nodes; v += 1 { dist[v] = INF; parent[v] = -1 }
        dist[source] = 0
        for _ := 0; _ < nodes; _ += 1 {
            chosen := -1
            for v := 0; v < nodes; v += 1 {
                if !used[v] && dist[v] != INF && (chosen < 0 || dist[v] < dist[chosen]) { chosen = v }
            }
            if chosen < 0 { break }
            used[chosen] = true
            for e := 0; e < edge_count; e += 1 {
                if edges[e].from != chosen || edges[e].capacity <= 0 { continue }
                v := edges[e].to
                candidate := dist[chosen] + edges[e].cost + potential[chosen] - potential[v]
                if !used[v] && candidate < dist[v] { dist[v] = candidate; parent[v] = e }
            }
        }
        if dist[sink] == INF { return -1 }
        for v := 0; v < nodes; v += 1 { if dist[v] != INF { potential[v] += dist[v] } }
        amount, path_cost := required-total_flow, i64(0)
        for v := sink; v != source; v = edges[parent[v]].from {
            e := parent[v]
            if e < 0 { return -1 }
            if amount > edges[e].capacity { amount = edges[e].capacity }
            path_cost += edges[e].cost
        }
        for v := sink; v != source; v = edges[parent[v]].from {
            e := parent[v]
            edges[e].capacity -= amount
            edges[edges[e].reverse].capacity += amount
        }
        total_flow += amount; total_cost += amount*path_cost
    }
    bits := u64(total_cost)
    for i := 0; i < 8; i += 1 { output[i] = u8(bits >> (8*i)) }
    return 8
}
