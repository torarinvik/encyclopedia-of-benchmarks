module heavy_light_path_max;

const int MAX_N = 64;
const int MAX_Q = 128;

fn void put_i64(char* output, usz slot, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[slot * 8 + byte] = (char)(bits >> (byte * 8));
}

fn long max_long(long left, long right) { return left > right ? left : right; }

fn long range_max(long* tree, int n, int left, int right) {
    int l = left + n, r = right + n + 1;
    long maximum = -2147483648;
    while (l < r) {
        if ((l & 1) != 0) { maximum = max_long(maximum, tree[l]); l++; }
        if ((r & 1) != 0) { r--; maximum = max_long(maximum, tree[r]); }
        l /= 2; r /= 2;
    }
    return maximum;
}

fn void point_set(long* tree, int n, int position, long value) {
    int p = position + n;
    tree[p] = value;
    while (p > 1) {
        p /= 2;
        tree[p] = max_long(tree[p * 2], tree[p * 2 + 1]);
    }
}

fn long path_max(long* tree, int n, int* parent, int* depth, int* head, int* position, int a, int b) {
    long maximum = -2147483648;
    while (head[a] != head[b]) {
        if (depth[head[a]] < depth[head[b]]) { int t = a; a = b; b = t; }
        maximum = max_long(maximum, range_max(tree, n, position[head[a]], position[a]));
        a = parent[head[a]];
    }
    if (depth[a] > depth[b]) { int t = a; a = b; b = t; }
    return max_long(maximum, range_max(tree, n, position[a], position[b]));
}

fn long heavy_light_path_max(long* input, usz length, char* output, usz capacity)
    @export("heavy_light_path_max") {
    if (input == null || length < 2) return -1;
    long nv = input[0], qv = input[1];
    if (nv < 1 || nv > MAX_N || qv < 0 || qv > MAX_Q) return -1;
    int n = (int)nv, q = (int)qv;
    if (length != 3 * (usz)n + 3 * (usz)q) return -1;

    long[MAX_N] values;
    usz cursor = 2;
    for (int v = 0; v < n; v++) {
        values[v] = input[cursor++];
        if (values[v] < -2147483648 || values[v] > 2147483647) return -1;
    }
    int[MAX_N * MAX_N] adjacency;
    int[MAX_N] degree;
    for (int i = 0; i < MAX_N * MAX_N; i++) adjacency[i] = 0;
    for (int i = 0; i < MAX_N; i++) degree[i] = 0;
    for (int edge = 0; edge < n - 1; edge++) {
        long uv = input[cursor++], vv = input[cursor++];
        if (uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv) return -1;
        int u = (int)uv, v = (int)vv;
        for (int i = 0; i < degree[u]; i++) if (adjacency[u * MAX_N + i] == v) return -1;
        adjacency[u * MAX_N + degree[u]++] = v;
        adjacency[v * MAX_N + degree[v]++] = u;
    }

    int[MAX_N] parent, depth, order, stack;
    for (int v = 0; v < n; v++) { parent[v] = -2; depth[v] = 0; }
    parent[0] = -1;
    int top = 0, order_count = 0;
    stack[top++] = 0;
    while (top > 0) {
        int u = stack[--top];
        order[order_count++] = u;
        for (int i = 0; i < degree[u]; i++) {
            int v = adjacency[u * MAX_N + i];
            if (v == parent[u]) continue;
            if (parent[v] != -2) return -1;
            parent[v] = u; depth[v] = depth[u] + 1; stack[top++] = v;
        }
    }
    if (order_count != n) return -1;
    int[MAX_N] subtree, heavy;
    for (int v = 0; v < n; v++) { subtree[v] = 1; heavy[v] = -1; }
    for (int i = n - 1; i > 0; i--) {
        int v = order[i], p = parent[v];
        subtree[p] += subtree[v];
        if (heavy[p] < 0 || subtree[v] > subtree[heavy[p]]) heavy[p] = v;
    }

    int[MAX_N] head, position, todo_vertex, todo_head;
    long[MAX_N] base;
    int todo = 0, timer = 0;
    todo_vertex[todo] = 0; todo_head[todo++] = 0;
    while (todo > 0) {
        todo--;
        int u = todo_vertex[todo], chain = todo_head[todo];
        while (u >= 0) {
            head[u] = chain; position[u] = timer; base[timer++] = values[u];
            for (int i = 0; i < degree[u]; i++) {
                int v = adjacency[u * MAX_N + i];
                if (parent[v] == u && v != heavy[u]) { todo_vertex[todo] = v; todo_head[todo++] = v; }
            }
            u = heavy[u];
        }
    }
    long[2 * MAX_N] segment;
    for (int i = 0; i < 2 * MAX_N; i++) segment[i] = 0;
    for (int i = 0; i < n; i++) segment[n + i] = base[i];
    for (int i = n - 1; i > 0; i--) segment[i] = max_long(segment[2 * i], segment[2 * i + 1]);

    long[MAX_Q] results;
    int result_count = 0;
    usz operations = cursor;
    for (int i = 0; i < q; i++) {
        long op = input[operations + 3 * (usz)i];
        long av = input[operations + 3 * (usz)i + 1];
        long bv = input[operations + 3 * (usz)i + 2];
        if (op == 0) {
            if (av < 0 || av >= nv || bv < -2147483648 || bv > 2147483647) return -1;
            values[(int)av] = bv;
            point_set(&segment[0], n, position[(int)av], bv);
        } else if (op == 1) {
            if (av < 0 || av >= nv || bv < 0 || bv >= nv) return -1;
            results[result_count++] = path_max(&segment[0], n, &parent[0], &depth[0], &head[0], &position[0], (int)av, (int)bv);
        } else return -1;
    }
    usz output_bytes = 8 * (usz)result_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    for (int i = 0; i < result_count; i++) put_i64(output, (usz)i, results[i]);
    return (long)output_bytes;
}
