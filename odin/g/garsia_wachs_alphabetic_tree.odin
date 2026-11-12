package garsia_wachs_alphabetic_tree

import "core:c"

MAX_N :: 64
MAX_NODE :: 2 * MAX_N - 1
MAX_INPUT :: MAX_N + 2
MAX_WEIGHT :: i64(1_000_000)
GW_INFINITY :: i64(1) << 62

put_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> (8 * byte))
    }
}

@(export)
garsia_wachs_alphabetic_tree :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > MAX_INPUT do return -1
    n_value := input[0]
    if n_value < 1 || n_value > MAX_N do return -1
    n := int(n_value)
    if int(input_length) != n + 1 do return -1

    node_weight: [MAX_NODE]i64
    left, right: [MAX_NODE]int
    active: [MAX_N]int
    for i := 0; i < n; i += 1 {
        if input[i + 1] < 0 || input[i + 1] > MAX_WEIGHT do return -1
        node_weight[i] = input[i + 1]
        left[i] = -1
        right[i] = -1
        active[i] = i
    }
    active_count, next_node := n, n
    for active_count > 1 {
        pair := 0
        for pair + 1 < active_count {
            following := GW_INFINITY
            if pair + 2 < active_count do following = node_weight[active[pair + 2]]
            if node_weight[active[pair]] <= following do break
            pair += 1
        }
        first, second := active[pair], active[pair + 1]
        combined := node_weight[first] + node_weight[second]
        node_weight[next_node] = combined
        left[next_node] = first
        right[next_node] = second
        earlier := pair
        for earlier > 0 && node_weight[active[earlier - 1]] < combined {
            earlier -= 1
        }
        insert_at := earlier
        for i := pair; i + 2 < active_count; i += 1 { active[i] = active[i + 2] }
        active_count -= 2
        for i := active_count; i > insert_at; i -= 1 { active[i] = active[i - 1] }
        active[insert_at] = next_node
        active_count += 1
        next_node += 1
    }

    depths: [MAX_N]int
    stack_node, stack_depth: [2 * MAX_N]int
    top := 1
    stack_node[0] = active[0]
    for top > 0 {
        top -= 1
        node, depth := stack_node[top], stack_depth[top]
        if node < n {
            depths[node] = depth
        } else {
            stack_node[top] = right[node]
            stack_depth[top] = depth + 1
            top += 1
            stack_node[top] = left[node]
            stack_depth[top] = depth + 1
            top += 1
        }
    }

    ordered_left, ordered_right: [MAX_NODE]int
    code_node, code_depth: [2 * MAX_N]int
    code_top, next_ordered := 0, n
    for leaf := 0; leaf < n; leaf += 1 {
        code_node[code_top] = leaf
        code_depth[code_top] = depths[leaf]
        code_top += 1
        for code_top >= 2 && code_depth[code_top - 1] == code_depth[code_top - 2] {
            level := code_depth[code_top - 1]
            if level <= 0 || next_ordered >= 2 * n - 1 do return -1
            ordered_left[next_ordered] = code_node[code_top - 2]
            ordered_right[next_ordered] = code_node[code_top - 1]
            code_top -= 2
            code_node[code_top] = next_ordered
            code_depth[code_top] = level - 1
            code_top += 1
            next_ordered += 1
        }
    }
    if code_top != 1 || code_depth[0] != 0 || next_ordered != 2 * n - 1 do return -1

    cost: i64 = 0
    for i := 0; i < n; i += 1 { cost += input[i + 1] * i64(depths[i]) }
    output_bytes := 8 * (n + 1)
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2
    put_i64(output, 0, cost)
    for i := 0; i < n; i += 1 { put_i64(output, 8 * (i + 1), i64(depths[i])) }
    return i64(output_bytes)
}
