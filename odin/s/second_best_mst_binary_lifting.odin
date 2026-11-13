package second_best_mst_binary_lifting

import "core:c"

Pair :: [2]i64

merge :: proc(a, b: Pair) -> Pair {
    result := Pair{-1, -1}
    for value in [4]i64{a[0], a[1], b[0], b[1]} {
        if value > result[0] {
            result[1] = result[0]
            result[0] = value
        } else if value < result[0] && value > result[1] {
            result[1] = value
        }
    }
    return result
}

root :: proc(parent: ^[8]int, initial: int) -> int {
    vertex := initial
    for parent[vertex] != vertex {
        parent[vertex] = parent[parent[vertex]]
        vertex = parent[vertex]
    }
    return vertex
}

@(export)
second_best_mst_binary_lifting :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 63 do return -1
    nv, mv := input[0], input[1]
    if nv < 1 || nv > 8 || mv < nv - 1 || mv > 20 || length != c.size_t(2 + 3 * mv) do return -1
    n, m := int(nv), int(mv)
    u, v, order: [20]int
    weight: [20]i64
    seen: [8][8]bool
    for i in 0..<m {
        a, b, w := input[2 + 3 * i], input[3 + 3 * i], input[4 + 3 * i]
        if a < 0 || a >= b || b >= nv || w < 0 || w > 1000000 do return -1
        if seen[int(a)][int(b)] do return -1
        seen[int(a)][int(b)] = true
        u[i], v[i], weight[i], order[i] = int(a), int(b), w, i
    }
    for i := 1; i < m; i += 1 {
        edge := order[i]
        j := i
        for j > 0 && weight[order[j - 1]] > weight[edge] {
            order[j] = order[j - 1]
            j -= 1
        }
        order[j] = edge
    }
    parent: [8]int
    selected: [20]bool
    adjacent, edge_at: [8][8]int
    degree: [8]int
    for i in 0..<n do parent[i] = i
    count := 0
    total: i64 = 0
    for i in 0..<m {
        edge := order[i]
        a, b := root(&parent, u[edge]), root(&parent, v[edge])
        if a == b do continue
        parent[a] = b
        selected[edge] = true
        count += 1
        total += weight[edge]
        adjacent[u[edge]][degree[u[edge]]] = v[edge]
        edge_at[u[edge]][degree[u[edge]]] = edge
        degree[u[edge]] += 1
        adjacent[v[edge]][degree[v[edge]]] = u[edge]
        edge_at[v[edge]][degree[v[edge]]] = edge
        degree[v[edge]] += 1
    }
    if count != n - 1 do return -1
    up: [4][8]int
    best: [4][8]Pair
    depth, queue: [8]int
    for level in 0..<4 {
        for vertex in 0..<n do best[level][vertex] = {-1, -1}
    }
    for vertex in 0..<n do depth[vertex] = -1
    depth[0] = 0
    queue[0] = 0
    head, tail := 0, 1
    for head < tail {
        vertex := queue[head]
        head += 1
        for i in 0..<degree[vertex] {
            next := adjacent[vertex][i]
            if depth[next] >= 0 do continue
            depth[next] = depth[vertex] + 1
            up[0][next] = vertex
            best[0][next] = {weight[edge_at[vertex][i]], -1}
            queue[tail] = next
            tail += 1
        }
    }
    for level in 1..<4 {
        for vertex in 0..<n {
            mid := up[level - 1][vertex]
            up[level][vertex] = up[level - 1][mid]
            best[level][vertex] = merge(best[level - 1][vertex], best[level - 1][mid])
        }
    }
    increase: i64 = -1
    for edge in 0..<m {
        if selected[edge] do continue
        a, b := u[edge], v[edge]
        if depth[a] < depth[b] { a, b = b, a }
        path := Pair{-1, -1}
        difference := depth[a] - depth[b]
        for level in 0..<4 {
            if difference & (1 << uint(level)) != 0 {
                path = merge(path, best[level][a])
                a = up[level][a]
            }
        }
        if a != b {
            for level := 3; level >= 0; level -= 1 {
                if up[level][a] != up[level][b] {
                    path = merge(merge(path, best[level][a]), best[level][b])
                    a, b = up[level][a], up[level][b]
                }
            }
            path = merge(merge(path, best[0][a]), best[0][b])
        }
        removed := path[1]
        if weight[edge] > path[0] do removed = path[0]
        if removed >= 0 && removed < weight[edge] {
            delta := weight[edge] - removed
            if increase < 0 || delta < increase do increase = delta
        }
    }
    if increase < 0 do return 0
    return total + increase + 1
}
