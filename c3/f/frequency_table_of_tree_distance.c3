module frequency_table_of_tree_distance;

const usz MAX_N = 64;
const usz MAX_INPUT_VALUES = 1 + 2 * (MAX_N - 1);

fn usz find_root(usz[MAX_N]* parent, usz item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

fn void solve_component(usz n, bool[MAX_N][MAX_N]* adjacent, bool[MAX_N]* removed,
    long[MAX_N]* answer, usz start) {
    usz[MAX_N] order, parent, subtree = zeroed, stack;
    usz order_count = 0, top = 0;
    stack[top++] = start;
    parent[start] = start;
    subtree[start] = 1;
    order[order_count++] = start;
    while (top > 0) {
        usz vertex = stack[--top];
        for (usz neighbor = 0; neighbor < n; neighbor += 1) {
            if (!adjacent[vertex][neighbor] || removed[neighbor] || neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            subtree[neighbor] = 1;
            order[order_count++] = neighbor;
            stack[top++] = neighbor;
        }
    }
    for (usz position = order_count; position > 1; position -= 1) {
        usz vertex = order[position - 1];
        subtree[parent[vertex]] += subtree[vertex];
    }

    usz centroid = MAX_N;
    for (usz position = 0; position < order_count; position += 1) {
        usz vertex = order[position];
        usz largest_part = order_count - subtree[vertex];
        for (usz neighbor = 0; neighbor < n; neighbor += 1) {
            if (adjacent[vertex][neighbor] && !removed[neighbor] && parent[neighbor] == vertex &&
                subtree[neighbor] > largest_part) largest_part = subtree[neighbor];
        }
        if (2 * largest_part <= order_count && (centroid == MAX_N || vertex < centroid)) centroid = vertex;
    }

    long[MAX_N] frequency = zeroed;
    usz frequency_max = 0;
    frequency[0] = 1;
    removed[centroid] = true;
    for (usz child = 0; child < n; child += 1) {
        if (!adjacent[centroid][child] || removed[child]) continue;
        usz[MAX_N] local_frequency = zeroed;
        usz[MAX_N] walk_vertex, walk_parent, walk_depth;
        usz local_max = 0, walk_top = 0;
        walk_vertex[walk_top] = child;
        walk_parent[walk_top] = centroid;
        walk_depth[walk_top] = 1;
        walk_top += 1;
        while (walk_top > 0) {
            walk_top -= 1;
            usz vertex = walk_vertex[walk_top];
            usz prev = walk_parent[walk_top];
            usz depth = walk_depth[walk_top];
            local_frequency[depth] += 1;
            if (depth > local_max) local_max = depth;
            for (usz neighbor = 0; neighbor < n; neighbor += 1) {
                if (adjacent[vertex][neighbor] && !removed[neighbor] && neighbor != prev) {
                    walk_vertex[walk_top] = neighbor;
                    walk_parent[walk_top] = vertex;
                    walk_depth[walk_top] = depth + 1;
                    walk_top += 1;
                }
            }
        }
        for (usz depth = 1; depth <= local_max; depth += 1)
            for (usz other = 0; other <= frequency_max && depth + other < n; other += 1)
                answer[depth + other] += (long)local_frequency[depth] * frequency[other];
        for (usz depth = 1; depth <= local_max; depth += 1)
            frequency[depth] += (long)local_frequency[depth];
        if (local_max > frequency_max) frequency_max = local_max;
    }

    for (usz child = 0; child < n; child += 1)
        if (adjacent[centroid][child] && !removed[child])
            solve_component(n, adjacent, removed, answer, child);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long frequency_table_of_tree_distance(long* input, usz length,
    char* output, usz capacity) @export("frequency_table_of_tree_distance") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * (n - 1)) return -1;

    bool[MAX_N][MAX_N] adjacent = zeroed;
    usz[MAX_N] dsu_parent, dsu_size;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        usz offset = 1 + 2 * edge;
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

    bool[MAX_N] removed = zeroed;
    long[MAX_N] answer = zeroed;
    solve_component(n, &adjacent, &removed, &answer, 0);
    usz required = 8 * (n - 1);
    if (output == null || capacity < required) return -2;
    for (usz distance = 1; distance < n; distance += 1)
        store_i64_le(output, 8 * (distance - 1), answer[distance]);
    return (long)required;
}
