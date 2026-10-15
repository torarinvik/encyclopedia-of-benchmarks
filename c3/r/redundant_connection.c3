module redundant_connection;

const usz MAX_VERTICES = 1000;

fn int find_root(int* parents, int node) {
    int root = node;
    while (parents[root] != root) root = parents[root];
    while (parents[node] != node) {
        int next = parents[node];
        parents[node] = root;
        node = next;
    }
    return root;
}

// Return the edge that first closes the cycle under input-order union-find.
fn long redundant_connection(long* values, usz length, char* output,
                             usz output_capacity) @export("redundant_connection") {
    if (length < 6 || length > 2 * MAX_VERTICES || length % 2 != 0 || values == null) return -1;
    usz edge_count = length / 2;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 1 || values[index] > (long)edge_count) return -1;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        if (values[2 * edge] == values[2 * edge + 1]) return -1;
    }

    int[MAX_VERTICES + 1] parents;
    for (usz node = 0; node <= edge_count; node++) { parents[node] = (int)node; }
    long redundant_left = 0;
    long redundant_right = 0;
    usz redundant_count = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        int left = (int)values[2 * edge];
        int right = (int)values[2 * edge + 1];
        int left_root = find_root(&parents[0], left);
        int right_root = find_root(&parents[0], right);
        if (left_root == right_root) {
            redundant_left = left;
            redundant_right = right;
            redundant_count++;
        } else {
            parents[left_root] = right_root;
        }
    }
    if (redundant_count != 1) return -1;
    if (output_capacity < 8 || output == null) return -2;
    uint[2] endpoints = {(uint)redundant_left, (uint)redundant_right};
    for (usz endpoint = 0; endpoint < 2; endpoint++) {
        for (usz byte = 0; byte < 4; byte++) {
            output[endpoint * 4 + byte] = (char)((endpoints[endpoint] >> (byte * 8)) & 255);
        }
    }
    return 2;
}
