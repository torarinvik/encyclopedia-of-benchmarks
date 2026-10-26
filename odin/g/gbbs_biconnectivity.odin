// Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile.
package gbbs_biconnectivity

import "core:c"

N :: 12
M :: 24
MAX_INPUT :: 2 + 2 * M
Matrix :: [N][N]bool

tree_edge :: proc(u, v: int, parent: [^]int) -> bool {
    return parent[u] == v || parent[v] == u
}
critical_edge :: proc(u, v: int, parent: [^]int, critical: [^]bool) -> bool {
    if parent[u] == v do return critical[u]
    if parent[v] == u do return critical[v]
    return false
}
parents_bfs :: proc(n: int, adjacent: Matrix, parent: [^]int, seen: [^]bool) {
    frontier: [N]int = {}
    next: [N]int = {}
    candidate: [N]int = {}
    for root := 0; root < n; root += 1 {
        if seen[root] do continue
        count := 1
        frontier[0] = root
        parent[root] = root
        seen[root] = true
        for count != 0 {
            has: [N]bool = {}
            for i := 0; i < count; i += 1 {
                vertex := frontier[i]
                for other := 0; other < n; other += 1 {
                    if adjacent[vertex][other] && !seen[other] {
                        if !has[other] || vertex < candidate[other] do candidate[other] = vertex
                        has[other] = true
                    }
                }
            }
            next_count := 0
            for other := 0; other < n; other += 1 {
                if has[other] {
                    parent[other] = candidate[other]
                    seen[other] = true
                    next[next_count] = other
                    next_count += 1
                }
            }
            for i := 0; i < next_count; i += 1 do frontier[i] = next[i]
            count = next_count
        }
    }
}
assign_preorder :: proc(n: int, parent: [^]int, pn: [^]int,
                        order: [^]int, size: [^]int) {
    stack: [N]int = {}
    global := 0
    for root := 0; root < n; root += 1 {
        if parent[root] != root do continue
        top, count, begin := 0, 0, global
        stack[top] = root
        top += 1
        for top != 0 {
            top -= 1
            vertex := stack[top]
            pn[vertex] = count
            count += 1
            order[global] = vertex
            global += 1
            for child := n; child > 0; child -= 1 {
                if child-1 != vertex && parent[child-1] == vertex {
                    stack[top] = child - 1
                    top += 1
                }
            }
        }
        i := global
        for i > begin {
            i -= 1
            vertex := order[i]
            if parent[vertex] != vertex do size[parent[vertex]] += size[vertex]
        }
    }
}

@(export)
gbbs_biconnectivity :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > N || m64 < 0 || m64 > M ||
        length != c.size_t(2 + 2*m64) do return -1
    n, m := int(n64), int(m64)
    adjacent: Matrix = {}
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[2+2*edge], input[3+2*edge]
        if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if adjacent[u][v] do return -1
        adjacent[u][v], adjacent[v][u] = true, true
    }
    if output == nil || capacity < c.size_t(m) do return -2
    parent: [N]int = {}
    pn, order: [N]int = {}, {}
    size: [N]int = {}
    seen, critical: [N]bool = {}, {}
    for v := 0; v < n; v += 1 { parent[v] = v; size[v] = 1 }
    parents_bfs(n, adjacent, &parent[0], &seen[0])
    assign_preorder(n, &parent[0], &pn[0], &order[0], &size[0])
    low, high: [N]int = {}, {}
    for v := 0; v < n; v += 1 {
        low[v] = pn[v]
        high[v] = pn[v] + size[v] - 1
    }
    for edge := 0; edge < m; edge += 1 {
        u, v := int(input[2+2*edge]), int(input[3+2*edge])
        if !tree_edge(u, v, &parent[0]) {
            if pn[u] < low[v] do low[v] = pn[u]
            else if pn[u] > high[v] do high[v] = pn[u]
            if pn[v] < low[u] do low[u] = pn[v]
            else if pn[v] > high[u] do high[u] = pn[v]
        }
    }
    for i := n; i > 0; i -= 1 {
        vertex := order[i-1]
        if parent[vertex] != vertex {
            p := parent[vertex]
            if low[vertex] < low[p] do low[p] = low[vertex]
            if high[vertex] > high[p] do high[p] = high[vertex]
        }
    }
    for v := 0; v < n; v += 1 {
        p := parent[v]
        if v != p && low[v] >= pn[p] && high[v] < pn[p] + size[p] do critical[v] = true
    }
    component, queue: [N]int = {}, {}
    for v := 0; v < n; v += 1 do component[v] = N
    for root := 0; root < n; root += 1 {
        if component[root] != N do continue
        head, tail := 0, 0
        component[root] = root
        queue[tail] = root
        tail += 1
        for head < tail {
            vertex := queue[head]
            head += 1
            for other := 0; other < n; other += 1 {
                if adjacent[vertex][other] && !critical_edge(vertex, other, &parent[0], &critical[0]) &&
                    component[other] == N {
                    component[other] = root
                    queue[tail] = other
                    tail += 1
                }
            }
        }
    }
    raw: [M]int = {}
    for edge := 0; edge < m; edge += 1 {
        u, v := int(input[2+2*edge]), int(input[3+2*edge])
        if parent[u] == v && critical[u] do raw[edge] = component[u]
        else if parent[v] == u && critical[v] do raw[edge] = component[v]
        else do raw[edge] = component[u]
    }
    for edge := 0; edge < m; edge += 1 {
        label := m
        for other := 0; other < m; other += 1 {
            if raw[other] == raw[edge] do label = min(label, other)
        }
        output[edge] = u8(label)
    }
    return i64(m)
}
