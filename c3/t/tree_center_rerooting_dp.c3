module tree_center_rerooting_dp;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + 2 * (MAX_N - 1);

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tree_center_rerooting_dp(long* input, usz length, char* output, usz capacity)
    @export("tree_center_rerooting_dp") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * (n - 1)) return -1;

    usz[MAX_N][MAX_N] adjacency = zeroed;
    usz[MAX_N] degree = zeroed;
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        usz offset = 1 + 2 * edge;
        long left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        usz left = (usz)left_value, right = (usz)right_value;
        adjacency[left][degree[left]] = right;
        degree[left] += 1;
        adjacency[right][degree[right]] = left;
        degree[right] += 1;
    }

    usz[MAX_N] parent;
    usz[MAX_N] order;
    for (usz vertex = 0; vertex < n; vertex += 1) parent[vertex] = MAX_N;
    parent[0] = MAX_N + 1;
    order[0] = 0;
    usz order_count = 1;
    for (usz position = 0; position < order_count; position += 1) {
        usz vertex = order[position];
        for (usz edge = 0; edge < degree[vertex]; edge += 1) {
            usz child = adjacency[vertex][edge];
            if (child == parent[vertex]) continue;
            if (parent[child] != MAX_N) return -1;
            parent[child] = vertex;
            order[order_count] = child;
            order_count += 1;
        }
    }
    if (order_count != n) return -1;

    usz[MAX_N] down = zeroed, best = zeroed, second = zeroed;
    usz[MAX_N] best_child;
    for (usz vertex = 0; vertex < n; vertex += 1) best_child[vertex] = MAX_N;
    usz position = n;
    while (position > 0) {
        position -= 1;
        usz vertex = order[position];
        for (usz edge = 0; edge < degree[vertex]; edge += 1) {
            usz child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            usz branch = down[child] + 1;
            if (branch > best[vertex]) {
                second[vertex] = best[vertex];
                best[vertex] = branch;
                best_child[vertex] = child;
            } else if (branch > second[vertex]) {
                second[vertex] = branch;
            }
        }
        down[vertex] = best[vertex];
    }

    long[MAX_N] outside;
    for (usz vertex = 0; vertex < n; vertex += 1) outside[vertex] = -1;
    for (usz i = 0; i < n; i += 1) {
        usz vertex = order[i];
        for (usz edge = 0; edge < degree[vertex]; edge += 1) {
            usz child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            usz sibling = best_child[vertex] == child ? second[vertex] : best[vertex];
            long base = outside[vertex] > (long)sibling ? outside[vertex] : (long)sibling;
            outside[child] = base + 1;
        }
    }

    usz radius = MAX_N;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        usz outside_height = outside[vertex] > 0 ? (usz)outside[vertex] : 0;
        usz eccentricity = down[vertex] > outside_height ? down[vertex] : outside_height;
        if (eccentricity < radius) radius = eccentricity;
    }
    long[2] centers;
    usz center_count = 0;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        usz outside_height = outside[vertex] > 0 ? (usz)outside[vertex] : 0;
        usz eccentricity = down[vertex] > outside_height ? down[vertex] : outside_height;
        if (eccentricity == radius) {
            centers[center_count] = (long)vertex;
            center_count += 1;
        }
    }
    usz required = 8 * center_count;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < center_count; i += 1) store_i64_le(output, 8 * i, centers[i]);
    return (long)required;
}
