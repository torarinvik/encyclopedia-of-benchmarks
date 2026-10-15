module diameter_of_binary_tree;

const usz MAX_NODE_COUNT = 1023;
const long ERROR_SENTINEL = -2000000000L;

fn long height_and_check(long* nodes, usz count, long node, bool* seen, usz* visited) {
    if (node == -1) return 0;
    if (node < 0 || (usz)node >= count) return ERROR_SENTINEL;
    usz index = (usz)node;
    if (seen[index]) return ERROR_SENTINEL;
    seen[index] = true;
    (*visited)++;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    if (left < -1 || right < -1 || (left >= 0 && (usz)left >= count) ||
        (right >= 0 && (usz)right >= count) ) return ERROR_SENTINEL;
    long left_height = height_and_check(nodes, count, left, seen, visited);
    if (left_height == ERROR_SENTINEL) return ERROR_SENTINEL;
    long right_height = height_and_check(nodes, count, right, seen, visited);
    if (right_height == ERROR_SENTINEL) return ERROR_SENTINEL;
    return 1 + (left_height > right_height ? left_height : right_height);
}

// Return the number of nodes on the longest path through root_index.
fn long diameter_of_binary_tree(long* nodes, usz node_count, long root_index)
    @export("diameter_of_binary_tree") {
    if (nodes == null || node_count == 0 || node_count > MAX_NODE_COUNT ||
        root_index < 0 || (usz)root_index >= node_count) return -1;
    bool[MAX_NODE_COUNT] seen;
    for (usz i = 0; i < node_count; i++) seen[i] = false;
    usz visited = 1;
    usz root = (usz)root_index;
    seen[root] = true;
    long left = nodes[3 * root + 1];
    long right = nodes[3 * root + 2];
    if (left < -1 || right < -1 || (left >= 0 && (usz)left >= node_count) ||
        (right >= 0 && (usz)right >= node_count)) return -1;
    long left_height = height_and_check(nodes, node_count, left, &seen[0], &visited);
    if (left_height == ERROR_SENTINEL) return -1;
    long right_height = height_and_check(nodes, node_count, right, &seen[0], &visited);
    if (right_height == ERROR_SENTINEL || visited != node_count) return -1;
    return left_height + right_height + 1;
}
