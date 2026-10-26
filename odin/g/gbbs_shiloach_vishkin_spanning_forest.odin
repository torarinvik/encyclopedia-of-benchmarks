// Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile.
package gbbs_shiloach_vishkin_spanning_forest

import "core:c"

N :: 12
M :: 24
MAX_INPUT :: 2 + 2 * M

find_root :: proc(parent: ^[N]int, vertex_in: int) -> int {
    vertex := vertex_in
    for parent[vertex] != vertex {
        parent[vertex] = parent[parent[vertex]]
        vertex = parent[vertex]
    }
    return vertex
}

@(export)
gbbs_shiloach_vishkin_spanning_forest :: proc "c" (input: [^]i64,
        length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > N || m64 < 0 || m64 > M ||
        length != c.size_t(2 + 2*m64) do return -1
    n, m := int(n64), int(m64)
    seen: [N][N]bool = {}
    edge_u, edge_v: [M]int = {}, {}
    for edge := 0; edge < m; edge += 1 {
        u64, v64 := input[2+2*edge], input[3+2*edge]
        if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 do return -1
        u, v := int(u64), int(v64)
        if seen[u][v] do return -1
        seen[u][v] = true
        edge_u[edge], edge_v[edge] = u, v
    }
    if output == nil || capacity < c.size_t(m) do return -2

    parent: [N]int = {}
    previous, next_parent, best_lower: [N]int = {}, {}, {}
    selected: [M]bool = {}
    for vertex := 0; vertex < n; vertex += 1 do parent[vertex] = vertex
    for round := 0; round < n; round += 1 {
        for vertex := 0; vertex < n; vertex += 1 {
            previous[vertex] = find_root(&parent, vertex)
            next_parent[vertex] = previous[vertex]
            best_lower[vertex] = n
        }
        for edge := 0; edge < m; edge += 1 {
            root_u, root_v := previous[edge_u[edge]], previous[edge_v[edge]]
            if root_u == root_v do continue
            lower, higher := min(root_u, root_v), max(root_u, root_v)
            if previous[higher] == higher && lower < best_lower[higher] do best_lower[higher] = lower
        }
        changed := false
        for higher := 0; higher < n; higher += 1 {
            lower := best_lower[higher]
            if lower == n do continue
            next_parent[higher] = lower
            changed = true
            for edge := 0; edge < m; edge += 1 {
                root_u, root_v := previous[edge_u[edge]], previous[edge_v[edge]]
                if (root_u == higher && root_v == lower) || (root_u == lower && root_v == higher) {
                    selected[edge] = true
                    break
                }
            }
        }
        for vertex := 0; vertex < n; vertex += 1 do parent[vertex] = find_root(&next_parent, vertex)
        if !changed do break
    }
    for edge := 0; edge < m; edge += 1 do output[edge] = if selected[edge] then 1 else 0
    return i64(m)
}
