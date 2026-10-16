package heavy_light_path_max

import "core:c"

MAX_N :: 64
MAX_Q :: 128

put_i64 :: proc "contextless" (output: [^]u8, slot: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[slot * 8 + byte] = u8(bits >> (8 * byte)) }
}

max_i64 :: proc "contextless" (a, b: i64) -> i64 {
    if a > b { return a }
    return b
}

range_max :: proc "contextless" (tree: [^]i64, n, left, right: int) -> i64 {
    l, r := left + n, right + n + 1
    maximum: i64 = -2147483648
    for l < r {
        if (l & 1) != 0 { maximum = max_i64(maximum, tree[l]); l += 1 }
        if (r & 1) != 0 { r -= 1; maximum = max_i64(maximum, tree[r]) }
        l /= 2
        r /= 2
    }
    return maximum
}

point_set :: proc "contextless" (tree: [^]i64, n, position: int, value: i64) {
    p := position + n
    tree[p] = value
    for p > 1 {
        p /= 2
        tree[p] = max_i64(tree[p * 2], tree[p * 2 + 1])
    }
}

path_max :: proc "contextless" (tree: [^]i64, n: int,
        parent, depth, head, position: [^]int, a_value, b_value: int) -> i64 {
    a, b := a_value, b_value
    maximum: i64 = -2147483648
    for head[a] != head[b] {
        if depth[head[a]] < depth[head[b]] { a, b = b, a }
        maximum = max_i64(maximum, range_max(tree, n, position[head[a]], position[a]))
        a = parent[head[a]]
    }
    if depth[a] > depth[b] { a, b = b, a }
    return max_i64(maximum, range_max(tree, n, position[a], position[b]))
}

@(export)
heavy_light_path_max :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 do return -1
    nv, qv := input[0], input[1]
    if nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q do return -1
    n, q := int(nv), int(qv)
    if length != c.size_t(3 * n + 3 * q) do return -1

    var values: [MAX_N]i64
    cursor := 2
    for v := 0; v < n; v += 1 {
        values[v] = input[cursor]
        if values[v] < -2147483648 || values[v] > 2147483647 do return -1
        cursor += 1
    }
    var adjacency: [MAX_N * MAX_N]int
    var degree: [MAX_N]int
    for edge := 0; edge < n - 1; edge += 1 {
        uv, vv := input[cursor], input[cursor + 1]
        cursor += 2
        if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv do return -1
        u, v := int(uv), int(vv)
        for i := 0; i < degree[u]; i += 1 { if adjacency[u * MAX_N + i] == v do return -1 }
        adjacency[u * MAX_N + degree[u]] = v
        degree[u] += 1
        adjacency[v * MAX_N + degree[v]] = u
        degree[v] += 1
    }

    var parent, depth, order, stack: [MAX_N]int
    for v := 0; v < n; v += 1 { parent[v] = -2 }
    parent[0] = -1
    top, order_count := 1, 0
    stack[0] = 0
    for top > 0 {
        top -= 1
        u := stack[top]
        order[order_count] = u
        order_count += 1
        for i := 0; i < degree[u]; i += 1 {
            v := adjacency[u * MAX_N + i]
            if v == parent[u] do continue
            if parent[v] != -2 do return -1
            parent[v] = u
            depth[v] = depth[u] + 1
            stack[top] = v
            top += 1
        }
    }
    if order_count != n do return -1

    var subtree, heavy: [MAX_N]int
    for v := 0; v < n; v += 1 { subtree[v] = 1; heavy[v] = -1 }
    for index := n - 1; index > 0; index -= 1 {
        v := order[index]
        p := parent[v]
        subtree[p] += subtree[v]
        if heavy[p] < 0 || subtree[v] > subtree[heavy[p]] { heavy[p] = v }
    }

    var head, position, todo_vertex, todo_head: [MAX_N]int
    var base: [MAX_N]i64
    todo, timer := 1, 0
    todo_vertex[0], todo_head[0] = 0, 0
    for todo > 0 {
        todo -= 1
        u, chain := todo_vertex[todo], todo_head[todo]
        for u >= 0 {
            head[u] = chain
            position[u] = timer
            base[timer] = values[u]
            timer += 1
            for i := 0; i < degree[u]; i += 1 {
                v := adjacency[u * MAX_N + i]
                if parent[v] == u && v != heavy[u] {
                    todo_vertex[todo], todo_head[todo] = v, v
                    todo += 1
                }
            }
            u = heavy[u]
        }
    }
    var segment: [MAX_N * 2]i64
    for i := 0; i < n; i += 1 { segment[n + i] = base[i] }
    for i := n - 1; i > 0; i -= 1 { segment[i] = max_i64(segment[i * 2], segment[i * 2 + 1]) }

    var results: [MAX_Q]i64
    result_count := 0
    operations := cursor
    for i := 0; i < q; i += 1 {
        op, av, bv := input[operations + 3 * i], input[operations + 3 * i + 1], input[operations + 3 * i + 2]
        if op == 0 {
            if av < 0 || av >= nv || bv < -2147483648 || bv > 2147483647 do return -1
            values[int(av)] = bv
            point_set(&segment[0], n, position[int(av)], bv)
        } else if op == 1 {
            if av < 0 || av >= nv || bv < 0 || bv >= nv do return -1
            results[result_count] = path_max(&segment[0], n, &parent[0], &depth[0], &head[0], &position[0], int(av), int(bv))
            result_count += 1
        } else do return -1
    }
    output_bytes := result_count * 8
    if output_bytes > 0 && (output == nil || capacity < c.size_t(output_bytes)) do return -2
    for i := 0; i < result_count; i += 1 { put_i64(output, i, results[i]) }
    return i64(output_bytes)
}
