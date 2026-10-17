package lca

import "core:c"

find_root :: proc(parent: [^]c.size_t, vertex: c.size_t) -> c.size_t {
    v := vertex
    for parent[v] != v {
        parent[v] = parent[parent[v]]
        v = parent[v]
    }
    return v
}

@(export)
lca :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 129 do return -1
    if input[0] < 1 || input[0] > 64 do return -1
    n := c.size_t(input[0])
    if length != 2*n+1 do return -1
    dsu: [64]c.size_t
    degree: [64]c.size_t
    adjacency: [64][64]c.size_t
    for i: c.size_t = 0; i < n; i += 1 { dsu[i] = i; degree[i] = 0 }
    pos: c.size_t = 1
    for edge: c.size_t = 0; edge+1 < n; edge += 1 {
        u_arg, v_arg := input[pos], input[pos+1]
        pos += 2
        if u_arg < 0 || u_arg >= i64(n) || v_arg < 0 || v_arg >= i64(n) || u_arg == v_arg do return -1
        u, v := c.size_t(u_arg), c.size_t(v_arg)
        ru, rv := find_root(&dsu[0],u), find_root(&dsu[0],v)
        if ru == rv do return -1
        dsu[ru] = rv
        adjacency[u][degree[u]] = v; degree[u] += 1
        adjacency[v][degree[v]] = u; degree[v] += 1
    }
    qa_arg, qb_arg := input[pos], input[pos+1]
    if qa_arg < 0 || qa_arg >= i64(n) || qb_arg < 0 || qb_arg >= i64(n) do return -1
    component := find_root(&dsu[0],0)
    for i: c.size_t = 1; i < n; i += 1 { if find_root(&dsu[0],i) != component do return -1 }

    parent: [64]c.size_t
    depth: [64]c.size_t
    stack: [64]c.size_t
    seen: [64]bool
    for i: c.size_t = 0; i < n; i += 1 { seen[i] = false }
    stack_size: c.size_t = 1
    stack[0] = 0; seen[0] = true
    for stack_size > 0 {
        stack_size -= 1
        vertex := stack[stack_size]
        for i: c.size_t = 0; i < degree[vertex]; i += 1 {
            next := adjacency[vertex][i]
            if !seen[next] {
                seen[next] = true; parent[next] = vertex; depth[next] = depth[vertex] + 1
                stack[stack_size] = next; stack_size += 1
            }
        }
    }
    a, b := c.size_t(qa_arg), c.size_t(qb_arg)
    if depth[a] < depth[b] { a, b = b, a }
    for depth[a] != depth[b] { a = parent[a] }
    if a == b do return i64(a)
    for a != b { a = parent[a]; b = parent[b] }
    return i64(a)
}
