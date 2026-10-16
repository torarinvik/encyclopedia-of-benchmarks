package binary_tree_node_count

import "core:c"

MAX_NODE_COUNT :: 900
INVALID_RESULT :: i64(-9_000_000_000_000_000_000)

count_visit :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, node: i64, depth: c.size_t) -> i64 {
    if node < 0 || u64(node) >= u64(node_count) || depth >= node_count do return INVALID_RESULT
    index := c.size_t(node)
    left, right := nodes[3 * index + 1], nodes[3 * index + 2]
    if left < -1 || right < -1 do return INVALID_RESULT
    if (left >= 0 && u64(left) >= u64(node_count)) || (right >= 0 && u64(right) >= u64(node_count)) do return INVALID_RESULT
    left_count: i64 = 0
    if left >= 0 {
        left_count = count_visit(nodes, node_count, left, depth + 1)
        if left_count == INVALID_RESULT do return INVALID_RESULT
    }
    right_count: i64 = 0
    if right >= 0 {
        right_count = count_visit(nodes, node_count, right, depth + 1)
        if right_count == INVALID_RESULT do return INVALID_RESULT
    }
    return 1 + left_count + right_count
}

@(export)
binary_tree_node_count :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, root_index: i64) -> i64 {
    if nodes == nil || node_count == 0 || node_count > MAX_NODE_COUNT || root_index < 0 || u64(root_index) >= u64(node_count) do return INVALID_RESULT
    return count_visit(nodes, node_count, root_index, 0)
}
