module check_if_binary_tree_balanced;

const usz MAX_NODE_COUNT = 1023;

fn long balanced_height(long* nodes, usz count, long node, bool* balanced) {
    if (node == -1 || !*balanced) return 0;
    if (node < 0 || (usz)node >= count) return -1;
    usz index = (usz)node;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (usz)left >= count) ||
        right < -1 || (right >= 0 && (usz)right >= count)) return -1;
    long left_height = balanced_height(nodes, count, left, balanced);
    if (left_height < 0) return -1;
    long right_height = balanced_height(nodes, count, right, balanced);
    if (right_height < 0) return -1;
    long difference = left_height >= right_height ? left_height - right_height : right_height - left_height;
    if (difference > 1) *balanced = false;
    return 1 + (left_height > right_height ? left_height : right_height);
}

fn long check_if_binary_tree_balanced(long* nodes, usz node_count, long root_index)
        @export("check_if_binary_tree_balanced") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    bool balanced = true;
    long height = balanced_height(nodes, node_count, root_index, &balanced);
    if (height < 0) return -1;
    return balanced ? 1 : 0;
}
