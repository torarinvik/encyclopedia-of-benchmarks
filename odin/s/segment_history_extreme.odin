package segment_history_extreme

import "core:c"

MAX_N :: 32
MAX_Q :: 32
TREE_SIZE :: 4 * MAX_N
MAX_INPUT :: 2 + MAX_N + 4 * MAX_Q
VALUE_LIMIT :: i64(1000)

ShNode :: struct {
    maximum: i64,
    history_maximum: i64,
    add: i64,
    add_peak: i64,
    set_value: i64,
    set_peak: i64,
    has_set: bool,
}

sh_apply_add_summary :: proc "contextless" (node: ^ShNode, net: i64, peak: i64) {
    node.history_maximum = max(node.history_maximum, node.maximum + peak)
    node.maximum += net
    if node.has_set {
        node.set_peak = max(node.set_peak, node.set_value + peak)
        node.set_value += net
    } else {
        node.add_peak = max(node.add_peak, node.add + peak)
        node.add += net
    }
}

sh_apply_add :: proc "contextless" (node: ^ShNode, delta: i64) {
    if node.has_set {
        node.set_peak = max(node.set_peak, node.set_value + delta)
        node.set_value += delta
    } else {
        node.add_peak = max(node.add_peak, node.add + delta)
        node.add += delta
    }
    node.history_maximum = max(node.history_maximum, node.maximum + delta)
    node.maximum += delta
}

sh_apply_set_summary :: proc "contextless" (node: ^ShNode, value: i64, peak: i64) {
    node.history_maximum = max(node.history_maximum, peak)
    node.maximum = value
    if node.has_set { node.set_peak = max(node.set_peak, peak) }
    else { node.has_set = true; node.set_peak = peak }
    node.set_value = value
}

sh_apply_set :: proc "contextless" (node: ^ShNode, value: i64) {
    node.history_maximum = max(node.history_maximum, value)
    node.maximum = value
    if node.has_set { node.set_peak = max(node.set_peak, value) }
    else { node.has_set = true; node.set_peak = value }
    node.set_value = value
}

sh_push :: proc "contextless" (tree: [^]ShNode, node: int) {
    parent := tree[node]
    if parent.add != 0 || parent.add_peak != 0 {
        sh_apply_add_summary(&tree[2 * node], parent.add, parent.add_peak)
        sh_apply_add_summary(&tree[2 * node + 1], parent.add, parent.add_peak)
        tree[node].add = 0
        tree[node].add_peak = 0
    }
    if parent.has_set {
        sh_apply_set_summary(&tree[2 * node], parent.set_value, parent.set_peak)
        sh_apply_set_summary(&tree[2 * node + 1], parent.set_value, parent.set_peak)
        tree[node].has_set = false
        tree[node].set_value = 0
        tree[node].set_peak = 0
    }
}

sh_pull :: proc "contextless" (tree: [^]ShNode, node: int) {
    tree[node].maximum = max(tree[2 * node].maximum, tree[2 * node + 1].maximum)
    tree[node].history_maximum = max(tree[2 * node].history_maximum, tree[2 * node + 1].history_maximum)
}

sh_build :: proc "contextless" (tree: [^]ShNode, values: [^]i64, node: int, left: int, right: int) {
    if right - left == 1 {
        tree[node].maximum = values[left]
        tree[node].history_maximum = values[left]
        return
    }
    middle := left + (right - left) / 2
    sh_build(tree, values, 2 * node, left, middle)
    sh_build(tree, values, 2 * node + 1, middle, right)
    sh_pull(tree, node)
}

sh_update :: proc "contextless" (tree: [^]ShNode, node: int, left: int, right: int,
    ql: int, qr: int, assignment: bool, value: i64) {
    if ql <= left && right <= qr {
        if assignment { sh_apply_set(&tree[node], value) }
        else { sh_apply_add(&tree[node], value) }
        return
    }
    sh_push(tree, node)
    middle := left + (right - left) / 2
    if ql < middle { sh_update(tree, 2 * node, left, middle, ql, qr, assignment, value) }
    if middle < qr { sh_update(tree, 2 * node + 1, middle, right, ql, qr, assignment, value) }
    sh_pull(tree, node)
}

sh_query :: proc "contextless" (tree: [^]ShNode, node: int, left: int, right: int,
    ql: int, qr: int, historical: bool) -> i64 {
    if ql <= left && right <= qr {
        if historical { return tree[node].history_maximum }
        return tree[node].maximum
    }
    sh_push(tree, node)
    middle := left + (right - left) / 2
    answer := i64(-1_000_000_000_000)
    if ql < middle { answer = sh_query(tree, 2 * node, left, middle, ql, qr, historical) }
    if middle < qr { answer = max(answer, sh_query(tree, 2 * node + 1, middle, right, ql, qr, historical)) }
    return answer
}

sh_write_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> (8 * byte)) }
}

@(export)
segment_history_extreme :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 2 || input_length > MAX_INPUT do return -1
    n_value, q_value := input[0], input[1]
    if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
    n, q := int(n_value), int(q_value)
    if int(input_length) != 2 + n + 4 * q do return -1
    for i := 0; i < n; i += 1 {
        if input[2 + i] < -VALUE_LIMIT || input[2 + i] > VALUE_LIMIT do return -1
    }
    operation_offset := 2 + n
    for i := 0; i < q; i += 1 {
        offset := operation_offset + 4 * i
        op, left, right, arg := input[offset], input[offset + 1], input[offset + 2], input[offset + 3]
        if op < 0 || op > 3 || left < 0 || right <= left || right > n_value do return -1
        if op < 2 {
            if arg < -VALUE_LIMIT || arg > VALUE_LIMIT do return -1
        } else if arg != 0 do return -1
    }

    tree: [TREE_SIZE]ShNode
    staged: [MAX_Q]i64
    answer_count := 0
    sh_build(&tree[0], input, 1, 0, n)
    for i := 0; i < q; i += 1 {
        offset := operation_offset + 4 * i
        op := int(input[offset])
        left, right := int(input[offset + 1]), int(input[offset + 2])
        if op < 2 { sh_update(&tree[0], 1, 0, n, left, right, op == 0, input[offset + 3]) }
        else {
            staged[answer_count] = sh_query(&tree[0], 1, 0, n, left, right, op == 3)
            answer_count += 1
        }
    }
    output_bytes := 8 * answer_count
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2
    for i := 0; i < answer_count; i += 1 { sh_write_i64(output, 8 * i, staged[i]) }
    return i64(output_bytes)
}
