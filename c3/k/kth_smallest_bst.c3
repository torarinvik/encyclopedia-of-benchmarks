module kth_smallest_bst;

const usz MAX_NODE_COUNT = 1023;
const long MAX_VALUE = 10000;
const long INVALID_TREE_RESULT = -9223372036854775807 - 1;

fn long kth_visit(long* nodes, usz node_count, long node, long* remaining) {
    if (node == -1) return -1;
    if (node < 0 || (usz)node >= node_count) return INVALID_TREE_RESULT;
    usz index = (usz)node;
    long value = nodes[3 * index];
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (value < 0 || value > MAX_VALUE || left < -1 || right < -1 ||
        (left >= 0 && (usz)left >= node_count) ||
        (right >= 0 && (usz)right >= node_count)) return INVALID_TREE_RESULT;
    long left_result = kth_visit(nodes, node_count, left, remaining);
    if (left_result >= 0 || left_result == INVALID_TREE_RESULT) return left_result;
    *remaining -= 1;
    if (*remaining == 0) return value;
    return kth_visit(nodes, node_count, right, remaining);
}

fn long kth_smallest_bst(long* nodes, usz node_count, long root_index, long k)
        @export("kth_smallest_bst") {
    if (node_count == 0 || node_count > MAX_NODE_COUNT || nodes == null ||
        root_index < 0 || (usz)root_index >= node_count || k < 1 || (usz)k > node_count) return -1;
    long remaining = k;
    long result = kth_visit(nodes, node_count, root_index, &remaining);
    return result >= 0 ? result : -1;
}
