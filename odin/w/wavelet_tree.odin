package wavelet_tree

import "core:c"

Max_N :: 64
Max_Q :: 128
Max_Nodes :: 768
Node :: struct {
    low, high: i64,
    left, right: int,
    prefix: [Max_N + 1]int,
}
Tree :: struct { nodes: [Max_Nodes]Node, used: int }

build :: proc "contextless" (tree: ^Tree, values: []i64, low, high: i64) -> int {
    id := tree.used
    tree.used += 1
    tree.nodes[id].low = low
    tree.nodes[id].high = high
    tree.nodes[id].left = -1
    tree.nodes[id].right = -1
    tree.nodes[id].prefix[0] = 0
    if low == high || len(values) == 0 do return id
    mid := low + (high - low) / 2
    left_values: [Max_N]i64
    right_values: [Max_N]i64
    left_count, right_count := 0, 0
    for i := 0; i < len(values); i += 1 {
        value := values[i]
        if value <= mid { left_values[left_count] = value; left_count += 1 }
        else { right_values[right_count] = value; right_count += 1 }
        tree.nodes[id].prefix[i + 1] = left_count
    }
    if left_count > 0 do tree.nodes[id].left = build(tree, left_values[:left_count], low, mid)
    if right_count > 0 do tree.nodes[id].right = build(tree, right_values[:right_count], mid + 1, high)
    return id
}

rank_prefix :: proc "contextless" (tree: ^Tree, node_id: int, value: i64, count: int) -> i64 {
    if node_id < 0 || count == 0 do return 0
    node := tree.nodes[node_id]
    if node.low == node.high { if node.low == value do return i64(count); return 0 }
    mid := node.low + (node.high - node.low) / 2
    left_count := node.prefix[count]
    if value <= mid do return rank_prefix(tree, node.left, value, left_count)
    return rank_prefix(tree, node.right, value, count - left_count)
}

quantile :: proc "contextless" (tree: ^Tree, node_id: int, left, right, k: int) -> i64 {
    node := tree.nodes[node_id]
    if node.low == node.high do return node.low
    left_before, left_after := node.prefix[left], node.prefix[right]
    in_left := left_after - left_before
    if k < in_left do return quantile(tree, node.left, left_before, left_after, k)
    return quantile(tree, node.right, left - left_before, right - left_after, k - in_left)
}

range_count :: proc "contextless" (tree: ^Tree, node_id: int, left, right: int, low, high: i64) -> i64 {
    if node_id < 0 || left >= right do return 0
    node := tree.nodes[node_id]
    if high < node.low || low > node.high do return 0
    if low <= node.low && node.high <= high do return i64(right - left)
    if node.low == node.high do return 0
    left_before, left_after := node.prefix[left], node.prefix[right]
    return range_count(tree, node.left, left_before, left_after, low, high) + range_count(tree, node.right, left - left_before, right - left_after, low, high)
}

@(export)
wavelet_tree_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || length > c.size_t(Max_N + 2 + 5 * Max_Q) do return -1
    if values[0] < 1 || values[0] > i64(Max_N) do return -1
    n := int(values[0])
    if length < c.size_t(n + 2) do return -1
    data: [Max_N]i64
    low, high := values[1], values[1]
    for i := 0; i < n; i += 1 {
        data[i] = values[i + 1]
        if data[i] < -1000 || data[i] > 1000 do return -1
        if data[i] < low do low = data[i]
        if data[i] > high do high = data[i]
    }
    q_value := values[n + 1]
    if q_value < 0 || q_value > i64(Max_Q) do return -1
    q := int(q_value)
    if length != c.size_t(n + 2 + 5 * q) do return -1
    tree: Tree = {}
    root := build(&tree, data[:n], low, high)
    total := i64(0)
    for j := 0; j < q; j += 1 {
        p := n + 2 + 5 * j
        op, a, b, cval, d := values[p], values[p + 1], values[p + 2], values[p + 3], values[p + 4]
        answer := i64(0)
        if op == 0 {
            if a < -1000 || a > 1000 || b < -1 || b >= i64(n) do return -1
            answer = rank_prefix(&tree, root, a, int(b + 1))
        } else if op == 1 {
            if a < 0 || b < a || b >= i64(n) || cval < 0 || cval > b - a do return -1
            answer = quantile(&tree, root, int(a), int(b + 1), int(cval))
        } else if op == 2 {
            if a < 0 || b < a || b >= i64(n) || cval > d || cval < -1000 || d > 1000 do return -1
            answer = range_count(&tree, root, int(a), int(b + 1), cval, d)
        } else { return -1 }
        total += i64(j + 1) * (answer + 1_000_001)
    }
    return total
}
