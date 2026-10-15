module binary_tree_inorder_traversal;

const usz MAX_NODE_COUNT = 100;

fn bool visit_inorder(long* nodes, usz node_count, long node,
        long* output, usz capacity, usz* used) {
    if (node == -1) return true;
    if (node < 0 || (usz)node >= node_count) return false;
    usz index = (usz)node;
    long value = nodes[3 * index];
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (value < -100 || value > 100 || left < -1 || right < -1 ||
        (left >= 0 && (usz)left >= node_count) ||
        (right >= 0 && (usz)right >= node_count)) return false;
    if (!visit_inorder(nodes, node_count, left, output, capacity, used)) return false;
    if (*used >= capacity) return false;
    output[*used] = value;
    *used += 1;
    return visit_inorder(nodes, node_count, right, output, capacity, used);
}

fn long binary_tree_inorder_traversal(long* nodes, usz node_count, long root_index,
        long* output, usz output_capacity) @export("binary_tree_inorder_traversal") {
    if (node_count > MAX_NODE_COUNT || output_capacity < node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == null || output == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    usz used = 0;
    if (!visit_inorder(nodes, node_count, root_index, output, output_capacity, &used) ||
        used != node_count) return -1;
    return (long)used;
}
