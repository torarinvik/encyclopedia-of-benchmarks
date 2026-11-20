module tree_center;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + 2 * (MAX_N - 1);

fn usz find_root(usz[MAX_N]* parent, usz item) {
    usz node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tree_center(long* input, usz length, char* output, usz capacity)
    @export("tree_center") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * (n - 1)) return -1;

    usz[MAX_N][MAX_N] adjacency = zeroed;
    usz[MAX_N] adjacency_count = zeroed;
    usz[MAX_N] degree = zeroed;
    usz[MAX_N] parent, component_size;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        parent[vertex] = vertex;
        component_size[vertex] = 1;
    }
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        usz offset = 1 + 2 * edge;
        long left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        usz left = (usz)left_value, right = (usz)right_value;
        usz root_left = find_root(&parent, left), root_right = find_root(&parent, right);
        if (root_left == root_right) return -1;
        if (component_size[root_left] < component_size[root_right]) {
            usz temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        parent[root_right] = root_left;
        component_size[root_left] += component_size[root_right];
        adjacency[left][adjacency_count[left]] = right;
        adjacency_count[left] += 1;
        adjacency[right][adjacency_count[right]] = left;
        adjacency_count[right] += 1;
        degree[left] += 1;
        degree[right] += 1;
    }
    if (n > 1 && component_size[find_root(&parent, 0)] != n) return -1;

    bool[MAX_N] active = zeroed;
    usz[MAX_N] leaves;
    usz leaf_count = 0;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        active[vertex] = true;
        if (degree[vertex] <= 1) {
            leaves[leaf_count] = vertex;
            leaf_count += 1;
        }
    }
    usz remaining = n;
    while (remaining > 2) {
        for (usz index = 0; index < leaf_count; index += 1) active[leaves[index]] = false;
        remaining -= leaf_count;
        for (usz index = 0; index < leaf_count; index += 1) {
            usz leaf = leaves[index];
            for (usz edge = 0; edge < adjacency_count[leaf]; edge += 1) {
                usz neighbor = adjacency[leaf][edge];
                if (active[neighbor]) degree[neighbor] -= 1;
            }
        }
        if (remaining <= 2) break;
        leaf_count = 0;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if (active[vertex] && degree[vertex] == 1) {
                leaves[leaf_count] = vertex;
                leaf_count += 1;
            }
        }
    }

    long[2] centers;
    usz center_count = 0;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        if (active[vertex]) {
            centers[center_count] = (long)vertex;
            center_count += 1;
        }
    }
    usz required = 8 * center_count;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < center_count; index += 1)
        store_i64_le(output, 8 * index, centers[index]);
    return (long)required;
}
