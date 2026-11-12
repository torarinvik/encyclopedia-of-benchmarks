module tree_edge_paint_path_count;

const int MAX_N = 16, MAX_Q = 32, MAX_EDGES = 15, LOG_N = 5;

fn int root_of(int* parents, int node) {
    while (parents[node] != node) { parents[node] = parents[parents[node]]; node = parents[node]; }
    return node;
}

fn void point_set(long* tree, int base, int index, long value) {
    int position = base + index; tree[position] = value;
    for (position /= 2; position > 0; position /= 2) tree[position] = tree[2 * position] + tree[2 * position + 1];
}

fn long range_sum(long* tree, int base, int left, int right) {
    if (left > right) return 0;
    int l = base + left, r = base + right + 1; long total = 0;
    while (l < r) {
        if (l & 1) total += tree[l++];
        if (r & 1) total += tree[--r];
        l /= 2; r /= 2;
    }
    return total;
}

fn int lca(int a, int b, int* depth, int* parent, int* ancestor) {
    if (depth[a] < depth[b]) { int t = a; a = b; b = t; }
    int difference = depth[a] - depth[b];
    for (int bit = 0; bit < LOG_N; bit++) if ((difference >> bit) & 1) a = ancestor[bit * MAX_N + a];
    if (a == b) return a;
    for (int bit = LOG_N - 1; bit >= 0; bit--) {
        if (ancestor[bit * MAX_N + a] != ancestor[bit * MAX_N + b]) {
            a = ancestor[bit * MAX_N + a]; b = ancestor[bit * MAX_N + b];
        }
    }
    return parent[a];
}

fn long tree_edge_paint_path_count(long* input, usz length) @export("tree_edge_paint_path_count") {
    if (input == null || length < 2 || length > 129) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return -1;
    int n = (int)input[0], q = (int)input[1];
    int m = n - 1;
    if (length != 2 + 2 * m + 3 * q) return -1;

    int[MAX_EDGES] edge_u = {}, edge_v = {}; int[MAX_N] dsu = {};
    for (int i = 0; i < n; i++) dsu[i] = i;
    usz cursor = 2;
    for (int e = 0; e < m; e++) {
        long u = input[cursor++], v = input[cursor++];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1;
        edge_u[e] = (int)u; edge_v[e] = (int)v;
        int ru = root_of(&dsu[0], edge_u[e]), rv = root_of(&dsu[0], edge_v[e]);
        if (ru == rv) return -1;
        dsu[ru] = rv;
    }
    for (int v = 1; v < n; v++) if (root_of(&dsu[0], v) != root_of(&dsu[0], 0)) return -1;

    int[MAX_N] parent = {}, depth = {}, first = {}, visited = {};
    int[MAX_EDGES] down = {}, up = {};
    int[MAX_N] stack_node = {}, stack_parent = {}, stack_in = {}, stack_cursor = {};
    int occurrence_count = 0, top = 0; visited[0] = 1;
    stack_node[0] = 0; stack_parent[0] = -1; stack_in[0] = -1;
    while (top >= 0) {
        int node = stack_node[top], found = 0;
        while (stack_cursor[top] < m) {
            int edge = stack_cursor[top]++;
            if (edge_u[edge] != node && edge_v[edge] != node) continue;
            int child = edge_u[edge] == node ? edge_v[edge] : edge_u[edge];
            if (child == stack_parent[top]) continue;
            if (visited[child]) return -1;
            visited[child] = 1; parent[child] = node; depth[child] = depth[node] + 1;
            down[edge] = occurrence_count++; first[child] = occurrence_count;
            top++; stack_node[top] = child; stack_parent[top] = node; stack_in[top] = edge; stack_cursor[top] = 0;
            found = 1; break;
        }
        if (!found) {
            int incoming = stack_in[top--];
            if (incoming >= 0) up[incoming] = occurrence_count++;
        }
    }

    int[MAX_N * LOG_N] ancestor = {};
    for (int v = 0; v < n; v++) ancestor[v] = parent[v];
    for (int k = 1; k < LOG_N; k++) for (int v = 0; v < n; v++) ancestor[k * MAX_N + v] = ancestor[(k - 1) * MAX_N + ancestor[(k - 1) * MAX_N + v]];
    int base = 1; while (base < occurrence_count) base *= 2;
    long[64] forward = {}, backward = {}; int[MAX_EDGES] painted = {};
    long total = 0;
    for (int i = 0; i < q; i++) {
        long kind = input[cursor++], a = input[cursor++], b = input[cursor++];
        if (kind == 0) {
            if (a < 0 || a >= m || b != 0) return -1;
            if (!painted[(int)a]) {
                painted[(int)a] = 1;
                point_set(&forward[0], base, down[(int)a], 1);
                point_set(&backward[0], base, up[(int)a], 1);
            }
        } else if (kind == 1) {
            if (a < 0 || a >= n || b < 0 || b >= n) return -1;
            int common = lca((int)a, (int)b, &depth[0], &parent[0], &ancestor[0]);
            int left_a = first[common], right_a = first[(int)a] - 1;
            int left_b = first[common], right_b = first[(int)b] - 1;
            total += range_sum(&forward[0], base, left_a, right_a) - range_sum(&backward[0], base, left_a, right_a);
            total += range_sum(&forward[0], base, left_b, right_b) - range_sum(&backward[0], base, left_b, right_b);
        } else return -1;
    }
    return total;
}
