module binary_tree_node_count;

const usz MAX_NODE_COUNT = 900;
const long INVALID_RESULT = -9000000000000000000;

fn long count_visit(long* nodes, usz node_count, long node, usz depth) {
    if (node < 0 || (usz)node >= node_count || depth >= node_count) return INVALID_RESULT;
    usz index = (usz)node;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 ||
        (left >= 0 && (usz)left >= node_count) || right < -1 ||
        (right >= 0 && (usz)right >= node_count)) return INVALID_RESULT;
    long left_count = left == -1 ? 0 : count_visit(nodes, node_count, left, depth + 1);
    if (left_count == INVALID_RESULT) return INVALID_RESULT;
    long right_count = right == -1 ? 0 : count_visit(nodes, node_count, right, depth + 1);
    if (right_count == INVALID_RESULT) return INVALID_RESULT;
    return 1 + left_count + right_count;
}

fn long binary_tree_node_count(long* nodes, usz node_count, long root_index)
        @export("binary_tree_node_count") {
    if (nodes == null || node_count == 0 || node_count > MAX_NODE_COUNT || root_index < 0 ||
        (usz)root_index >= node_count) return INVALID_RESULT;
    return count_visit(nodes, node_count, root_index, 0);
}
