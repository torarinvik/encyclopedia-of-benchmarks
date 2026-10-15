module validate_bst;

const usz MAX_NODE_COUNT = 1023;
const long VALUE_MIN = -2147483648;
const long VALUE_MAX = 2147483647;

fn long validate_subtree(long* nodes, usz node_count, long node,
                         bool has_lower, long lower, bool has_upper, long upper) {
    if (node == -1) {
        return 1;
    }
    if (node < 0 || (usz)node >= node_count) {
        return -1;
    }
    usz index = (usz)node;
    long value = nodes[3 * index];
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (value < VALUE_MIN || value > VALUE_MAX ||
        left < -1 || (left >= 0 && (usz)left >= node_count) ||
        right < -1 || (right >= 0 && (usz)right >= node_count)) {
        return -1;
    }
    if ((has_lower && value <= lower) || (has_upper && value >= upper)) {
        return 0;
    }
    long left_result = validate_subtree(nodes, node_count, left, has_lower, lower, true, value);
    if (left_result <= 0) {
        return left_result;
    }
    return validate_subtree(nodes, node_count, right, true, value, has_upper, upper);
}

fn long validate_bst(long* nodes, usz node_count, long root_index) @export("validate_bst") {
    if (node_count > MAX_NODE_COUNT) {
        return -1;
    }
    if (node_count == 0) {
        return root_index == -1 ? 1 : -1;
    }
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) {
        return -1;
    }
    return validate_subtree(nodes, node_count, root_index, false, 0, false, 0);
}
