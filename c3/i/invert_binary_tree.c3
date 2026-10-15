module invert_binary_tree;

const MAX_NODE_COUNT = 1023;
const MAX_TREE_HEIGHT = 512;

fn bool validate_subtree(long* nodes, usz node_count, long index, usz depth, bool* visited) {
    if (index == -1) return true;
    if (index < 0 || (ulong)index >= node_count || depth > MAX_TREE_HEIGHT) return false;
    usz node = (usz)index;
    if (visited[node]) return false;
    visited[node] = true;
    usz offset = node * 3;
    long value = nodes[offset];
    long left = nodes[offset + 1];
    long right = nodes[offset + 2];
    if (value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
        (left >= 0 && (ulong)left >= node_count) || (right >= 0 && (ulong)right >= node_count)) return false;
    return validate_subtree(nodes, node_count, left, depth + 1, visited) &&
           validate_subtree(nodes, node_count, right, depth + 1, visited);
}

fn void invert_subtree(long* nodes, long index) {
    if (index == -1) return;
    usz offset = (usz)index * 3;
    long left = nodes[offset + 1];
    nodes[offset + 1] = nodes[offset + 2];
    nodes[offset + 2] = left;
    invert_subtree(nodes, nodes[offset + 1]);
    invert_subtree(nodes, nodes[offset + 2]);
}

fn void store_i64_little_endian(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[position + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Return a mirrored copy of a valid indexed binary tree in little-endian triplets.
fn long invert_binary_tree(long* values, usz length, char* output, usz output_capacity)
        @export("invert_binary_tree") {
    if (length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * MAX_NODE_COUNT) return -1;
    usz node_count = (length - 1) / 3;
    long root = values[0];
    if (node_count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || (ulong)root >= node_count) return -1;

    long[3 * MAX_NODE_COUNT] nodes;
    bool[MAX_NODE_COUNT] visited;
    for (usz index = 0; index < 3 * node_count; index++) nodes[index] = values[index + 1];
    for (usz index = 0; index < node_count; index++) visited[index] = false;
    if (!validate_subtree(&nodes[0], node_count, root, 1, &visited[0])) return -1;
    for (usz index = 0; index < node_count; index++) if (!visited[index]) return -1;

    usz output_length = 24 * node_count;
    if (output == null || output_capacity < output_length) return -2;
    invert_subtree(&nodes[0], root);
    for (usz index = 0; index < 3 * node_count; index++)
        store_i64_little_endian(nodes[index], output, 8 * index);
    return (long)node_count;
}
