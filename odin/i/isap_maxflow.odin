package isap_maxflow

import "core:c"

N_MAX :: 8
M_MAX :: 24
INPUT_MAX :: 77

isap_dfs :: proc(u, sink, n: int, amount: i64, residual: ^[64]i64,
    distance: ^[8]i64, gap: ^[9]i64, current: ^[8]int, stopped: ^bool) -> i64 {
    if u == sink do return amount
    for current[u] < n {
        v := current[u]
        edge := u * 8 + v
        if residual[edge] > 0 && distance[u] == distance[v] + 1 {
            limit := amount
            if residual[edge] < limit do limit = residual[edge]
            sent := isap_dfs(v, sink, n, limit, residual, distance, gap, current, stopped)
            if sent > 0 { residual[edge] -= sent; residual[v * 8 + u] += sent; return sent }
            if stopped^ do return 0
        }
        current[u] += 1
    }
    old := distance[u]
    best := i64(n)
    for v := 0; v < n; v += 1 {
        if residual[u * 8 + v] > 0 && distance[v] < best do best = distance[v]
    }
    replacement := best + 1
    if replacement > i64(n) do replacement = i64(n)
    gap[int(old)] -= 1
    distance[u] = replacement
    gap[int(replacement)] += 1
    current[u] = 0
    if old < i64(n) && gap[int(old)] == 0 do stopped^ = true
    return 0
}

@(export)
isap_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > c.size_t(INPUT_MAX) do return -1
    nv, mv, sv, tv := input[0], input[1], input[2], input[3]
    if nv < 2 || nv > N_MAX || mv < 0 || mv > M_MAX || sv < 0 || sv >= nv || tv < 0 || tv >= nv || sv == tv do return -1
    n, m, source, sink := int(nv), int(mv), int(sv), int(tv)
    if length != c.size_t(4 + 3 * m) do return -1
    residual: [64]i64
    for e := 0; e < m; e += 1 {
        u, v, capacity := input[4 + 3 * e], input[5 + 3 * e], input[6 + 3 * e]
        if u < 0 || u >= nv || v < 0 || v >= nv || u == v || capacity < 0 || capacity > 100 do return -1
        residual[int(u) * 8 + int(v)] += capacity
    }
    distance: [8]i64
    gap: [9]i64
    current: [8]int
    queue: [8]int
    for v := 0; v < n; v += 1 do distance[v] = i64(n)
    distance[sink] = 0
    head, tail := 0, 1
    queue[0] = sink
    for head < tail {
        v := queue[head]
        head += 1
        for p := 0; p < n; p += 1 {
            if distance[p] == i64(n) && residual[p * 8 + v] > 0 {
                distance[p] = distance[v] + 1
                queue[tail] = p
                tail += 1
            }
        }
    }
    if distance[source] >= i64(n) do return 0
    for v := 0; v < n; v += 1 do gap[int(distance[v])] += 1
    stopped := false
    flow: i64 = 0
    for distance[source] < i64(n) && !stopped do flow += isap_dfs(source, sink, n, 2400, &residual, &distance, &gap, &current, &stopped)
    return flow
}
