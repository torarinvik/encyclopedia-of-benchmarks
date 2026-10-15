module binary_tree_node_sum

const max_node_count = 900
const invalid_result = i64(-9_000_000_000_000_000_000)

fn sum_visit(nodes &i64, node_count usize, node i64, depth usize) i64 {
    if node < 0 || u64(node) >= u64(node_count) || depth >= node_count { return invalid_result }
    index := usize(node)
    unsafe {
        value := nodes[3 * index]
        left := nodes[3 * index + 1]
        right := nodes[3 * index + 2]
        if value < -1_000_000_000 || value > 1_000_000_000 || left < -1 || right < -1 { return invalid_result }
        if (left >= 0 && u64(left) >= u64(node_count)) || (right >= 0 && u64(right) >= u64(node_count)) { return invalid_result }
        left_sum := if left == -1 { i64(0) } else { sum_visit(nodes, node_count, left, depth + 1) }
        if left_sum == invalid_result { return invalid_result }
        right_sum := if right == -1 { i64(0) } else { sum_visit(nodes, node_count, right, depth + 1) }
        if right_sum == invalid_result { return invalid_result }
        return value + left_sum + right_sum
    }
}

@[export: 'binary_tree_node_sum']
pub fn binary_tree_node_sum(nodes &i64, node_count usize, root_index i64) i64 {
    if node_count == 0 || node_count > max_node_count || root_index < 0 || u64(root_index) >= u64(node_count) {
        return invalid_result
    }
    return sum_visit(nodes, node_count, root_index, 0)
}
