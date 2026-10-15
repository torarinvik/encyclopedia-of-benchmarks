module even_tree;

const long INVALID_RESULT = (-9223372036854775807L - 1L);

fn long even_tree(long* values, usz length) @export("even_tree") {
    if (values == null || length < 2) return INVALID_RESULT;
    long n_value = values[0], edge_value = values[1];
    if (n_value < 2 || n_value > 100 || n_value % 2 != 0 || edge_value != n_value - 1) return INVALID_RESULT;
    usz n = (usz)n_value, edge_count = (usz)edge_value;
    if (length != 2 + 2 * edge_count) return INVALID_RESULT;
    bool[100][100] adjacency = zeroed;
    for (usz i = 0; i < edge_count; i++) {
        long u_value = values[2 + 2 * i], v_value = values[3 + 2 * i];
        if (u_value < 1 || u_value > n_value || v_value < 1 || v_value > n_value || u_value == v_value) return INVALID_RESULT;
        usz u = (usz)(u_value - 1), v = (usz)(v_value - 1);
        if (adjacency[u][v]) return INVALID_RESULT;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    int[100] parents;
    int[100] stack;
    int[100] order;
    long[100] subtree;
    for (usz i = 0; i < n; i++) { parents[i] = -2; subtree[i] = 1; }
    parents[0] = -1;
    usz top = 0, order_count = 0;
    stack[top++] = 0;
    while (top > 0) {
        int u = stack[--top];
        order[order_count++] = u;
        for (usz v = 0; v < n; v++) if (adjacency[u][v] && parents[v] == -2) {
            parents[v] = u;
            stack[top++] = (int)v;
        }
    }
    if (order_count != n) return INVALID_RESULT;
    long cuts = 0;
    usz i = order_count;
    while (i > 0) {
        i--;
        int u = order[i];
        if (parents[u] >= 0) subtree[(usz)parents[u]] += subtree[u];
        if (subtree[u] % 2 == 0) cuts++;
    }
    return cuts - 1;
}
