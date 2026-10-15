module univalued_binary_tree;

const usz MAX_NODE_COUNT = 1023;

fn long is_univalued(long* nodes, usz node_count, long node) {
    if (node == -1) return 1;
    if (node < 0 || (usz)node >= node_count) return -1;
    usz index = (usz)node;
    long value = nodes[3 * index];
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (usz)left >= node_count) ||
        right < -1 || (right >= 0 && (usz)right >= node_count)) return -1;
    if ((left >= 0 && nodes[3 * (usz)left] != value) ||
        (right >= 0 && nodes[3 * (usz)right] != value)) return 0;
    long left_result = is_univalued(nodes, node_count, left);
    if (left_result <= 0) return left_result;
    return is_univalued(nodes, node_count, right);
}

fn long univalued_binary_tree(long* nodes, usz node_count, long root_index)
        @export("univalued_binary_tree") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    return is_univalued(nodes, node_count, root_index);
}
