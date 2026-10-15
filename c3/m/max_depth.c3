module max_depth;

const usz MAX_NODE_COUNT = 1023;

fn long depth(long* nodes, usz node_count, long node) {
    if (node == -1) return 0;
    if (node < 0 || (usz)node >= node_count) return -1;
    usz index = (usz)node;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && (usz)left >= node_count) ||
        right < -1 || (right >= 0 && (usz)right >= node_count)) return -1;
    long left_depth = depth(nodes, node_count, left);
    if (left_depth < 0) return -1;
    long right_depth = depth(nodes, node_count, right);
    if (right_depth < 0) return -1;
    return 1 + (left_depth > right_depth ? left_depth : right_depth);
}

fn long max_depth(long* nodes, usz node_count, long root_index)
        @export("max_depth") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    return depth(nodes, node_count, root_index);
}
