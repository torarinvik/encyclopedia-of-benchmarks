package lowest_common_ancestor_binary_lifting

import "core:c"

MAX_NODES :: 256
MAX_QUERIES :: 1024
MAX_ARCS :: 510
LOG_LEVELS :: 9

@(export)
lowest_common_ancestor_binary_lifting :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || input[0] < 1 || input[0] > MAX_NODES do return -1
    node_count := int(input[0])
    if input[1] < 0 || input[1] >= i64(node_count) || input[2] != i64(node_count - 1) ||
        input[3] < 0 || input[3] > MAX_QUERIES do return -1
    edge_count := int(input[2])
    query_count := int(input[3])
    query_offset := 4 + 2 * edge_count
    if int(length) != query_offset + 2 * query_count do return -1
    root := int(input[1])

    head := [MAX_NODES]int{}
    arc_to := [MAX_ARCS]int{}
    arc_next := [MAX_ARCS]int{}
    parent := [MAX_NODES]int{}
    depth := [MAX_NODES]usize{}
    up := [LOG_LEVELS * MAX_NODES]usize{}
    stack := [MAX_NODES]int{}
    for node := 0; node < node_count; node += 1 {
        head[node] = -1
        parent[node] = -2
    }
    arcs := 0
    for edge := 0; edge < edge_count; edge += 1 {
        left_value := input[4 + 2 * edge]
        right_value := input[5 + 2 * edge]
        if left_value < 0 || left_value >= i64(node_count) || right_value < 0 || right_value >= i64(node_count) || left_value == right_value do return -1
        left := int(left_value)
        right := int(right_value)
        arc_to[arcs] = right; arc_next[arcs] = head[left]; head[left] = arcs; arcs += 1
        arc_to[arcs] = left; arc_next[arcs] = head[right]; head[right] = arcs; arcs += 1
    }
    for query := 0; query < query_count; query += 1 {
        for side := 0; side < 2; side += 1 {
            value := input[query_offset + 2 * query + side]
            if value < 0 || value >= i64(node_count) do return -1
        }
    }
    top := 0
    reached := 0
    parent[root] = -1
    up[root] = usize(root)
    stack[top] = root
    top += 1
    for top > 0 {
        top -= 1
        node := stack[top]
        reached += 1
        arc := head[node]
        for arc >= 0 {
            neighbor := arc_to[arc]
            if neighbor != parent[node] {
                if parent[neighbor] != -2 do return -1
                parent[neighbor] = node
                depth[neighbor] = depth[node] + 1
                up[neighbor] = usize(node)
                stack[top] = neighbor
                top += 1
            }
            arc = arc_next[arc]
        }
    }
    if reached != node_count do return -1
    if output_capacity < c.size_t(query_count) do return -2
    for level := 1; level < LOG_LEVELS; level += 1 {
        for node := 0; node < node_count; node += 1 {
            middle := up[(level - 1) * MAX_NODES + node]
            up[level * MAX_NODES + node] = up[(level - 1) * MAX_NODES + int(middle)]
        }
    }
    for query := 0; query < query_count; query += 1 {
        u := int(input[query_offset + 2 * query])
        v := int(input[query_offset + 2 * query + 1])
        if depth[u] < depth[v] { temp := u; u = v; v = temp }
        difference := depth[u] - depth[v]
        for level := 0; level < LOG_LEVELS; level += 1 {
            if difference & (1 << level) != 0 do u = int(up[level * MAX_NODES + u])
        }
        if u != v {
            for level := LOG_LEVELS - 1; level >= 0; level -= 1 {
                up_u := int(up[level * MAX_NODES + u])
                up_v := int(up[level * MAX_NODES + v])
                if up_u != up_v { u = up_u; v = up_v }
            }
            u = int(up[u])
        }
        output[query] = u8(u)
    }
    return i64(query_count)
}
