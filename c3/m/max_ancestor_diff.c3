module max_ancestor_diff;

const usz MAX_NODE_COUNT = 1023;

fn long absolute_difference(long left, long right) {
    return left >= right ? left - right : right - left;
}

fn long visit(long* nodes, usz node_count, long node, long path_min, long path_max) {
    if (node == -1) return 0;
    if (node < 0 || (usz)node >= node_count) return -1;
    usz index = (usz)node;
    long value = nodes[3 * index];
    if (value < -100000 || value > 100000) return -1;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (usz)left >= node_count) ||
        right < -1 || (right >= 0 && (usz)right >= node_count)) return -1;
    long best = absolute_difference(path_min, value);
    long high_difference = absolute_difference(path_max, value);
    if (high_difference > best) best = high_difference;
    long low = value < path_min ? value : path_min;
    long high = value > path_max ? value : path_max;
    long left_best = visit(nodes, node_count, left, low, high);
    if (left_best < 0) return -1;
    long right_best = visit(nodes, node_count, right, low, high);
    if (right_best < 0) return -1;
    if (left_best > best) best = left_best;
    if (right_best > best) best = right_best;
    return best;
}

fn long max_ancestor_diff(long* nodes, usz node_count, long root_index)
        @export("max_ancestor_diff") {
    if (node_count == 0 || node_count > MAX_NODE_COUNT || nodes == null ||
        root_index < 0 || (usz)root_index >= node_count) return -1;
    long root_value = nodes[3 * (usz)root_index];
    if (root_value < -100000 || root_value > 100000) return -1;
    return visit(nodes, node_count, root_index, root_value, root_value);
}
