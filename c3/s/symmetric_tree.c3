module symmetric_tree;

const usz MAX_NODE_COUNT = 1023;

fn long symmetric_tree_mirror(long* nodes, usz node_count, long left, long right) {
    if (left == -1 || right == -1) return left == right ? 1 : 0;
    if (left < 0 || right < 0 || (usz)left >= node_count || (usz)right >= node_count) return -1;
    usz left_node = (usz)left;
    usz right_node = (usz)right;
    if (nodes[3 * left_node] != nodes[3 * right_node]) return 0;
    long left_left = nodes[3 * left_node + 1];
    long left_right = nodes[3 * left_node + 2];
    long right_left = nodes[3 * right_node + 1];
    long right_right = nodes[3 * right_node + 2];
    if (left_left < -1 || (left_left >= 0 && (usz)left_left >= node_count) ||
        left_right < -1 || (left_right >= 0 && (usz)left_right >= node_count) ||
        right_left < -1 || (right_left >= 0 && (usz)right_left >= node_count) ||
        right_right < -1 || (right_right >= 0 && (usz)right_right >= node_count)) return -1;
    long outer = symmetric_tree_mirror(nodes, node_count, left_left, right_right);
    if (outer != 1) return outer;
    return symmetric_tree_mirror(nodes, node_count, left_right, right_left);
}

fn long symmetric_tree(long* nodes, usz node_count, long root_index) @export("symmetric_tree") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;
    usz root = (usz)root_index;
    long left = nodes[3 * root + 1];
    long right = nodes[3 * root + 2];
    if (left < -1 || (left >= 0 && (usz)left >= node_count) ||
        right < -1 || (right >= 0 && (usz)right >= node_count)) return -1;
    return symmetric_tree_mirror(nodes, node_count, left, right);
}
