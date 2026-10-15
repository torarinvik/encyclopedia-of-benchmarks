module binary_tree_maximum_path_sum;

const usz MAX_NODE_COUNT = 1023;
const long ERROR_SENTINEL = -2000000000;

fn long maximum_gain(long* nodes, usz node_count, long node, long* best_path) {
    if (node == -1) return 0;
    if (node < 0 || (usz)node >= node_count) return ERROR_SENTINEL;
    usz index = (usz)node;
    long value = nodes[3 * index];
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (value < -1000 || value > 1000 || left < -1 ||
        (left >= 0 && (usz)left >= node_count) || right < -1 ||
        (right >= 0 && (usz)right >= node_count)) return ERROR_SENTINEL;
    long left_gain = maximum_gain(nodes, node_count, left, best_path);
    if (left_gain == ERROR_SENTINEL) return ERROR_SENTINEL;
    long right_gain = maximum_gain(nodes, node_count, right, best_path);
    if (right_gain == ERROR_SENTINEL) return ERROR_SENTINEL;
    long positive_left = left_gain > 0 ? left_gain : 0;
    long positive_right = right_gain > 0 ? right_gain : 0;
    long through_node = value + positive_left + positive_right;
    if (through_node > best_path[0]) best_path[0] = through_node;
    return value + (positive_left > positive_right ? positive_left : positive_right);
}

fn long binary_tree_maximum_path_sum(long* nodes, usz node_count, long root_index)
        @export("binary_tree_maximum_path_sum") {
    if (node_count == 0 || node_count > MAX_NODE_COUNT || nodes == null ||
        root_index < 0 || (usz)root_index >= node_count) return -1;
    long best_path = -2147483648;
    long gain = maximum_gain(nodes, node_count, root_index, &best_path);
    return gain == ERROR_SENTINEL ? -1 : best_path;
}
