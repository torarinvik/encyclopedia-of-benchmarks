module connected_components_with_dsu;

const usz MAX_NODE_COUNT = 256;
const usz MAX_EDGE_COUNT = 2047;

fn usz find_root(usz* parent, usz node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn long connected_components_with_dsu(long* input, usz length)
    @export("connected_components_with_dsu") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_NODE_COUNT ||
        input[1] < 0 || input[1] > (long)MAX_EDGE_COUNT) return -1;
    usz node_count = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    usz[MAX_NODE_COUNT + 1] parent;
    usz[MAX_NODE_COUNT + 1] set_size;
    for (usz node = 1; node <= node_count; node++) {
        parent[node] = node;
        set_size[node] = 1;
    }
    usz component_count = node_count;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_arg = input[2 + 2 * edge];
        long right_arg = input[3 + 2 * edge];
        if (left_arg < 1 || left_arg > (long)node_count ||
            right_arg < 1 || right_arg > (long)node_count) return -1;
        usz left = find_root(&parent[0], (usz)left_arg);
        usz right = find_root(&parent[0], (usz)right_arg);
        if (left == right) continue;
        if (set_size[left] < set_size[right]) {
            usz temporary = left;
            left = right;
            right = temporary;
        }
        parent[right] = left;
        set_size[left] += set_size[right];
        component_count--;
    }
    return (long)component_count;
}
