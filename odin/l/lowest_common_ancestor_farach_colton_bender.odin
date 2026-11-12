package lowest_common_ancestor_farach_colton_bender

import "core:c"

MAX_NODES :: 256
MAX_QUERIES :: 1024
MAX_ARCS :: 510
MAX_EULER :: 2 * MAX_NODES - 1
MAX_BLOCKS :: 128
MAX_LEVELS :: 8
MAX_MICRO :: 4

shallower :: proc "contextless" (depth: ^[MAX_EULER]int, a, b: int) -> int {
    if depth^[a] < depth^[b] do return a
    if depth^[b] < depth^[a] do return b
    if a < b do return a
    return b
}

range_minimum :: proc "contextless" (first, last, euler_count, block_size: int,
    depth: ^[MAX_EULER]int, pattern: ^[MAX_BLOCKS]int, micro: ^[8 * 4 * 4]int,
    macro_table: ^[MAX_LEVELS * MAX_BLOCKS]int, logs: ^[MAX_BLOCKS + 1]int) -> int {
    block_a, block_b := first / block_size, last / block_size
    offset_a, offset_b := first % block_size, last % block_size
    if block_a == block_b do return block_a * block_size + micro^[(pattern^[block_a] * 4 + offset_a) * 4 + offset_b]
    base_a, base_b := block_a * block_size, block_b * block_size
    len_a := block_size
    if euler_count - base_a < len_a do len_a = euler_count - base_a
    best := base_a + micro^[(pattern^[block_a] * 4 + offset_a) * 4 + len_a - 1]
    right_best := base_b + micro^[(pattern^[block_b] * 4) * 4 + offset_b]
    best = shallower(depth, best, right_best)
    if block_b > block_a + 1 {
        lo, hi := block_a + 1, block_b - 1
        count := hi - lo + 1
        level := logs^[count]
        span := 1 << level
        best = shallower(depth, best, macro_table^[level * MAX_BLOCKS + lo])
        best = shallower(depth, best, macro_table^[level * MAX_BLOCKS + hi - span + 1])
    }
    return best
}

@(export)
lowest_common_ancestor_farach_colton_bender :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || input[0] < 1 || input[0] > MAX_NODES do return -1
    node_count := int(input[0])
    if input[1] < 0 || input[1] >= i64(node_count) || input[2] != i64(node_count - 1) ||
        input[3] < 0 || input[3] > MAX_QUERIES do return -1
    edge_count, query_count := int(input[2]), int(input[3])
    query_offset := 4 + 2 * edge_count
    if length != c.size_t(query_offset + 2 * query_count) do return -1
    root := int(input[1])

    head: [MAX_NODES]int
    arc_to, arc_next: [MAX_ARCS]int
    parent, tree_depth, first: [MAX_NODES]int
    euler, euler_depth: [MAX_EULER]int
    stack_node, stack_arc: [MAX_NODES]int
    for node := 0; node < node_count; node += 1 { head[node] = -1; parent[node] = -2 }
    arcs := 0
    for edge := 0; edge < edge_count; edge += 1 {
        u, v := input[4 + 2 * edge], input[5 + 2 * edge]
        if u < 0 || u >= i64(node_count) || v < 0 || v >= i64(node_count) || u == v do return -1
        a, b := int(u), int(v)
        arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = arcs; arcs += 1
        arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = arcs; arcs += 1
    }
    for query := 0; query < query_count; query += 1 {
        for side := 0; side < 2; side += 1 {
            node := input[query_offset + 2 * query + side]
            if node < 0 || node >= i64(node_count) do return -1
        }
    }

    euler_count, top, reached := 1, 1, 1
    parent[root] = -1; first[root] = 0; euler[0] = root
    stack_node[0] = root; stack_arc[0] = head[root]
    for top > 0 {
        slot := top - 1
        node := stack_node[slot]
        arc := stack_arc[slot]
        if arc < 0 {
            top -= 1
            if top > 0 {
                up := stack_node[top - 1]
                euler[euler_count] = up
                euler_depth[euler_count] = tree_depth[up]
                euler_count += 1
            }
            continue
        }
        stack_arc[slot] = arc_next[arc]
        neighbor := arc_to[arc]
        if neighbor == parent[node] do continue
        if parent[neighbor] != -2 do return -1
        parent[neighbor] = node
        tree_depth[neighbor] = tree_depth[node] + 1
        first[neighbor] = euler_count
        euler[euler_count] = neighbor
        euler_depth[euler_count] = tree_depth[neighbor]
        euler_count += 1
        reached += 1
        stack_node[top] = neighbor; stack_arc[top] = head[neighbor]; top += 1
    }
    if reached != node_count do return -1
    if output_capacity < c.size_t(query_count) || (query_count > 0 && output == nil) do return -2

    logarithm := 0
    value := euler_count
    for value > 1 { value /= 2; logarithm += 1 }
    block_size := logarithm / 2
    if block_size < 1 do block_size = 1
    block_count := (euler_count + block_size - 1) / block_size
    micro: [8 * 4 * 4]int
    pattern: [MAX_BLOCKS]int
    logs: [MAX_BLOCKS + 1]int
    macro_table: [MAX_LEVELS * MAX_BLOCKS]int
    shape_count := 1 << (block_size - 1)
    for shape := 0; shape < shape_count; shape += 1 {
        relative: [MAX_MICRO]int
        for step := 0; step + 1 < block_size; step += 1 {
            direction := -1
            if ((shape >> step) & 1) != 0 do direction = 1
            relative[step + 1] = relative[step] + direction
        }
        for left := 0; left < block_size; left += 1 {
            for right := left; right < block_size; right += 1 {
                best := left
                for at := left + 1; at <= right; at += 1 {
                    if relative[at] < relative[best] do best = at
                }
                micro[(shape * 4 + left) * 4 + right] = best
            }
        }
    }
    for block := 0; block < block_count; block += 1 {
        base := block * block_size
        end := base + block_size
        if end > euler_count do end = euler_count
        best := base
        pattern[block] = 0
        for at := base; at + 1 < end; at += 1 {
            if euler_depth[at + 1] > euler_depth[at] do pattern[block] |= 1 << (at - base)
            best = shallower(&euler_depth, best, at + 1)
        }
        macro_table[block] = best
    }
    logs[0] = 0; logs[1] = 0
    for count := 2; count <= block_count; count += 1 { logs[count] = logs[count / 2] + 1 }
    macro_levels := 1
    for (1 << macro_levels) <= block_count && macro_levels < MAX_LEVELS {
        half := 1 << (macro_levels - 1)
        span := 2 * half
        for block := 0; block + span <= block_count; block += 1 {
            macro_table[macro_levels * MAX_BLOCKS + block] = shallower(&euler_depth,
                macro_table[(macro_levels - 1) * MAX_BLOCKS + block],
                macro_table[(macro_levels - 1) * MAX_BLOCKS + block + half])
        }
        macro_levels += 1
    }

    answers: [MAX_QUERIES]u8
    for query := 0; query < query_count; query += 1 {
        u, v := int(input[query_offset + 2 * query]), int(input[query_offset + 2 * query + 1])
        left, right := first[u], first[v]
        if left > right { temp := left; left = right; right = temp }
        at := range_minimum(left, right, euler_count, block_size, &euler_depth, &pattern, &micro, &macro_table, &logs)
        answers[query] = u8(euler[at])
    }
    for query := 0; query < query_count; query += 1 { output[query] = answers[query] }
    return i64(query_count)
}
