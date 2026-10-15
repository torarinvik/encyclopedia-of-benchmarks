package binary_tree_node_sum

import "core:c"

MAX_NODE_COUNT :: 900
INVALID_RESULT :: i64(-9_000_000_000_000_000_000)

sum_visit :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, node: i64, depth: c.size_t) -> i64 {
    if node < 0 || u64(node) >= u64(node_count) || depth >= node_count do return INVALID_RESULT
    index := c.size_t(node)
    value, left, right := nodes[3 * index], nodes[3 * index + 1], nodes[3 * index + 2]
    if value < -1_000_000_000 || value > 1_000_000_000 || left < -1 || right < -1 do return INVALID_RESULT
    if (left >= 0 && u64(left) >= u64(node_count)) || (right >= 0 && u64(right) >= u64(node_count)) do return INVALID_RESULT
    left_sum: i64 = 0
    if left >= 0 {
        left_sum = sum_visit(nodes, node_count, left, depth + 1)
        if left_sum == INVALID_RESULT do return INVALID_RESULT
    }
    right_sum: i64 = 0
    if right >= 0 {
        right_sum = sum_visit(nodes, node_count, right, depth + 1)
        if right_sum == INVALID_RESULT do return INVALID_RESULT
    }
    return value + left_sum + right_sum
}

@(export)
binary_tree_node_sum :: proc "contextless" (nodes: [^]i64, node_count: c.size_t, root_index: i64) -> i64 {
    if nodes == nil || node_count == 0 || node_count > MAX_NODE_COUNT || root_index < 0 || u64(root_index) >= u64(node_count) do return INVALID_RESULT
    return sum_visit(nodes, node_count, root_index, 0)
}
