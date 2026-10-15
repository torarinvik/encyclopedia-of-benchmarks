module sum_of_left_leaves;

const usz MAX_NODE_COUNT = 1023;
const long ERROR_SENTINEL = -2000000000;

fn long visit(long* nodes, usz node_count, long node, bool is_left) {
    if (node == -1) return 0;
    if (node < 0 || (usz)node >= node_count) return ERROR_SENTINEL;
    usz index = (usz)node;
    long value = nodes[3 * index];
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (value < -1000 || value > 1000 || left < -1 ||
        (left >= 0 && (usz)left >= node_count) || right < -1 ||
        (right >= 0 && (usz)right >= node_count)) return ERROR_SENTINEL;
    if (left == -1 && right == -1) return is_left ? value : 0;
    long left_sum = visit(nodes, node_count, left, true);
    if (left_sum == ERROR_SENTINEL) return ERROR_SENTINEL;
    long right_sum = visit(nodes, node_count, right, false);
    if (right_sum == ERROR_SENTINEL) return ERROR_SENTINEL;
    return left_sum + right_sum;
}

fn long sum_of_left_leaves(long* nodes, usz node_count, long root_index)
        @export("sum_of_left_leaves") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    long result = visit(nodes, node_count, root_index, false);
    return result == ERROR_SENTINEL ? -1 : result;
}
