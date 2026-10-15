module flatten_binarytree_to_linkedlist;

const MAX_NODE_COUNT = 1023;
const MAX_TREE_HEIGHT = 512;

fn bool validate(long* nodes, usz count, long index, usz depth, bool* visited, usz* seen) {
    if (index == -1) return true;
    if (index < 0 || (ulong)index >= count || depth > MAX_TREE_HEIGHT || visited[index]) return false;
    visited[index] = true;
    *seen += 1;
    usz off = (usz)index * 3;
    long value = nodes[off], left = nodes[off + 1], right = nodes[off + 2];
    if (value < -2147483648 || value > 2147483647 || left < -1 || right < -1 ||
        (left >= 0 && (ulong)left >= count) || (right >= 0 && (ulong)right >= count)) return false;
    return validate(nodes, count, left, depth + 1, visited, seen) &&
           validate(nodes, count, right, depth + 1, visited, seen);
}

fn void flatten(long* nodes, long index) {
    if (index == -1) return;
    usz off = (usz)index * 3;
    long left = nodes[off + 1];
    flatten(nodes, left);
    long original_right = nodes[off + 2];
    nodes[off + 2] = left;
    nodes[off + 1] = -1;
    long tail = index;
    while (nodes[(usz)tail * 3 + 2] != -1) tail = nodes[(usz)tail * 3 + 2];
    nodes[(usz)tail * 3 + 2] = original_right;
    flatten(nodes, original_right);
}

fn void store_i64(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { output[position + b] = (char)(bits & 255); bits >>= 8; }
}

fn long flatten_binarytree_to_linkedlist(long* values, usz length, char* output, usz capacity)
        @export("flatten_binarytree_to_linkedlist") {
    if (length < 1 || (length - 1) % 3 != 0 || length > 1 + 3 * MAX_NODE_COUNT) return -1;
    usz count = (length - 1) / 3;
    long root = values[0];
    if (count == 0) return root == -1 ? 0 : -1;
    if (root < 0 || (ulong)root >= count) return -1;
    long[MAX_NODE_COUNT * 3] nodes;
    bool[MAX_NODE_COUNT] visited;
    for (usz i = 0; i < 3 * count; i++) nodes[i] = values[i + 1];
    for (usz i = 0; i < count; i++) visited[i] = false;
    usz seen = 0;
    if (!validate(&nodes[0], count, root, 1, &visited[0], &seen) || seen != count) return -1;
    if (output == null || capacity < 24 * count) return -2;
    flatten(&nodes[0], root);
    for (usz i = 0; i < count; i++) {
        store_i64(nodes[3 * i], output, 24 * i);
        store_i64(nodes[3 * i + 1], output, 24 * i + 8);
        store_i64(nodes[3 * i + 2], output, 24 * i + 16);
    }
    return (long)count;
}
