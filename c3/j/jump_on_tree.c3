module jump_on_tree;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const usz MAX_LEVELS = 7;
const usz MAX_INPUT_VALUES = 2 + 2 * (MAX_N - 1) + 3 * MAX_Q;

fn usz find_root(usz[MAX_N]* parent, usz item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

fn usz lift(usz[MAX_N][MAX_LEVELS]* ancestors, usz vertex, usz distance) {
    for (usz bit = 0; bit < MAX_LEVELS; bit += 1)
        if (((distance >> bit) & 1) != 0) vertex = ancestors[vertex][bit];
    return vertex;
}

fn usz lowest_common_ancestor(usz[MAX_N][MAX_LEVELS]* ancestors,
    usz[MAX_N]* depth, usz left, usz right) {
    if (depth[left] < depth[right]) {
        usz temporary = left;
        left = right;
        right = temporary;
    }
    left = lift(ancestors, left, depth[left] - depth[right]);
    if (left == right) return left;
    for (usz level = MAX_LEVELS; level > 0; level -= 1) {
        usz bit = level - 1;
        if (ancestors[left][bit] != ancestors[right][bit]) {
            left = ancestors[left][bit];
            right = ancestors[right][bit];
        }
    }
    return ancestors[left][0];
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long jump_on_tree(long* input, usz length, char* output, usz capacity)
    @export("jump_on_tree") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 2 || n_value > (long)MAX_N || q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    usz query_start = 2 + 2 * (n - 1);
    if (length != query_start + 3 * q) return -1;

    bool[MAX_N][MAX_N] adjacent = zeroed;
    usz[MAX_N] dsu_parent, dsu_size;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        usz offset = 2 + 2 * edge;
        long left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
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
    }

    usz[MAX_N][MAX_LEVELS] ancestors = zeroed;
    usz[MAX_N] depth = zeroed;
    bool[MAX_N] visited = zeroed;
    usz[MAX_N] stack;
    usz top = 1;
    stack[0] = 0;
    visited[0] = true;
    while (top > 0) {
        top -= 1;
        usz vertex = stack[top];
        for (usz neighbor = 0; neighbor < n; neighbor += 1) {
            if (!adjacent[vertex][neighbor] || visited[neighbor]) continue;
            visited[neighbor] = true;
            ancestors[neighbor][0] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            stack[top] = neighbor;
            top += 1;
        }
    }
    for (usz level = 1; level < MAX_LEVELS; level += 1)
        for (usz vertex = 0; vertex < n; vertex += 1)
            ancestors[vertex][level] = ancestors[ancestors[vertex][level - 1]][level - 1];

    long[MAX_Q] answers;
    for (usz query = 0; query < q; query += 1) {
        usz offset = query_start + 3 * query;
        long start_value = input[offset], target_value = input[offset + 1];
        long index_value = input[offset + 2];
        if (start_value < 0 || start_value >= n_value || target_value < 0 ||
            target_value >= n_value || index_value < 0 || index_value >= n_value) return -1;
        usz start = (usz)start_value, target = (usz)target_value, index = (usz)index_value;
        usz common = lowest_common_ancestor(&ancestors, &depth, start, target);
        usz upward = depth[start] - depth[common];
        usz path_length = upward + depth[target] - depth[common];
        if (index > path_length) answers[query] = -1;
        else if (index <= upward) answers[query] = (long)lift(&ancestors, start, index);
        else answers[query] = (long)lift(&ancestors, target, path_length - index);
    }

    usz required = 8 * q;
    if (output == null || capacity < required) return -2;
    for (usz query = 0; query < q; query += 1)
        store_i64_le(output, 8 * query, answers[query]);
    return (long)required;
}
