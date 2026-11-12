module tree_diameter;

const usz MAX_N = 64;
const usz MAX_INPUT_VALUES = 1 + 3 * (MAX_N - 1);
const usz MAX_OUTPUT_VALUES = 2 + MAX_N;

fn usz find_root(usz[MAX_N]* parent, usz item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

fn void traverse(usz n, usz start, bool[MAX_N][MAX_N]* adjacent,
    long[MAX_N][MAX_N]* weight, long[MAX_N]* distance, long[MAX_N]* path_parent) {
    usz[MAX_N] stack;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        distance[vertex] = -1;
        path_parent[vertex] = -1;
    }
    usz top = 1;
    stack[0] = start;
    distance[start] = 0;
    while (top > 0) {
        usz vertex = stack[top - 1];
        top -= 1;
        for (usz neighbor = 0; neighbor < n; neighbor += 1) {
            if (!adjacent[vertex][neighbor] || distance[neighbor] >= 0) continue;
            distance[neighbor] = distance[vertex] + weight[vertex][neighbor];
            path_parent[neighbor] = (long)vertex;
            stack[top] = neighbor;
            top += 1;
        }
    }
}

fn usz farthest(usz n, long[MAX_N]* distance) {
    usz best = 0;
    for (usz vertex = 1; vertex < n; vertex += 1) {
        if (distance[vertex] > distance[best] ||
            (distance[vertex] == distance[best] && vertex < best)) best = vertex;
    }
    return best;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tree_diameter(long* input, usz length, char* output, usz capacity)
    @export("tree_diameter") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 3 * (n - 1)) return -1;

    bool[MAX_N][MAX_N] adjacent = zeroed;
    long[MAX_N][MAX_N] weight = zeroed;
    usz[MAX_N] dsu_parent, dsu_size;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        usz offset = 1 + 3 * edge;
        long left_value = input[offset], right_value = input[offset + 1];
        long edge_weight = input[offset + 2];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value ||
            edge_weight < 1 || edge_weight > 1000000000) return -1;
        usz left = (usz)left_value, right = (usz)right_value;
        usz root_left = find_root(&dsu_parent, left);
        usz root_right = find_root(&dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            usz temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = true;
        adjacent[right][left] = true;
        weight[left][right] = edge_weight;
        weight[right][left] = edge_weight;
    }

    long[MAX_N] distance, path_parent;
    traverse(n, 0, &adjacent, &weight, &distance, &path_parent);
    usz first_endpoint = farthest(n, &distance);
    traverse(n, first_endpoint, &adjacent, &weight, &distance, &path_parent);
    usz second_endpoint = farthest(n, &distance);
    usz[MAX_N] reverse_path;
    usz path_length = 0;
    long current = (long)second_endpoint;
    while (current >= 0) {
        reverse_path[path_length] = (usz)current;
        path_length += 1;
        if ((usz)current == first_endpoint) break;
        current = path_parent[(usz)current];
    }

    long[MAX_OUTPUT_VALUES] staged;
    usz used = 0;
    staged[used++] = distance[second_endpoint];
    staged[used++] = (long)path_length;
    for (usz position = 0; position < path_length; position += 1)
        staged[used++] = (long)reverse_path[path_length - 1 - position];
    usz required = 8 * used;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < used; index += 1)
        store_i64_le(output, 8 * index, staged[index]);
    return (long)required;
}
