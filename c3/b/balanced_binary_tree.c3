module balanced_binary_tree;

const usz MAX_NODE_COUNT = 1023;

fn long tree_height(long* nodes, usz node_count, long node) {
    if (node == -1) return 0;
    if (node < 0 || (usz)node >= node_count) return -1;
    usz index = (usz)node;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (usz)left >= node_count) ||
        right < -1 || (right >= 0 && (usz)right >= node_count)) return -1;
    long left_height = tree_height(nodes, node_count, left);
    if (left_height < 0) return -1;
    long right_height = tree_height(nodes, node_count, right);
    if (right_height < 0) return -1;
    return 1 + (left_height > right_height ? left_height : right_height);
}

fn long is_balanced(long* nodes, usz node_count, long node) {
    if (node == -1) return 1;
    if (node < 0 || (usz)node >= node_count) return -1;
    usz index = (usz)node;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (usz)left >= node_count) ||
        right < -1 || (right >= 0 && (usz)right >= node_count)) return -1;
    long left_height = tree_height(nodes, node_count, left);
    if (left_height < 0) return -1;
    long right_height = tree_height(nodes, node_count, right);
    if (right_height < 0) return -1;
    long difference = left_height >= right_height
        ? left_height - right_height : right_height - left_height;
    if (difference > 1) return 0;
    long left_balanced = is_balanced(nodes, node_count, left);
    if (left_balanced <= 0) return left_balanced;
    return is_balanced(nodes, node_count, right);
}

fn long balanced_binary_tree(long* nodes, usz node_count, long root_index)
        @export("balanced_binary_tree") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    return is_balanced(nodes, node_count, root_index);
}
