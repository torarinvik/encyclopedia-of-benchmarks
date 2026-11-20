module dynamic_tree_maximum_weight_independent_set;

const int MAX_N = 64;
const int MAX_Q = 64;
const usz MAX_INPUT = 320;
const long MAX_WEIGHT = 1000000;
const long NEG = -1152921504606846976;

struct Matrix { long[2][2] a; }

fn long max64(long a, long b) { return a > b ? a : b; }

fn Matrix identity() {
    Matrix m;
    m.a[0][0] = 0; m.a[0][1] = NEG;
    m.a[1][0] = NEG; m.a[1][1] = 0;
    return m;
}

fn Matrix multiply(Matrix left, Matrix right) {
    Matrix result;
    for (int i = 0; i < 2; i++) for (int j = 0; j < 2; j++) {
        long first = left.a[i][0] + right.a[0][j];
        long second = left.a[i][1] + right.a[1][j];
        result.a[i][j] = max64(first, second);
    }
    return result;
}

fn int find_root(int* parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

fn void set_matrix(Matrix* tree, int position, Matrix value) {
    int node = MAX_N + position;
    tree[node] = value;
    node /= 2;
    while (node > 0) {
        tree[node] = multiply(tree[2 * node], tree[2 * node + 1]);
        node /= 2;
    }
}

fn Matrix query(Matrix* tree, int left, int right) {
    Matrix before = identity(); Matrix after = identity();
    left += MAX_N; right += MAX_N;
    while (left < right) {
        if ((left & 1) != 0) { before = multiply(before, tree[left]); left++; }
        if ((right & 1) != 0) { right--; after = multiply(tree[right], after); }
        left /= 2; right /= 2;
    }
    return multiply(before, after);
}

fn void summary(Matrix* tree, int* position, int* tail, int head, long* result) {
    Matrix p = query(tree, position[head], position[tail[head]] + 1);
    result[0] = max64(p.a[0][0], p.a[0][1]);
    result[1] = max64(p.a[1][0], p.a[1][1]);
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (int byte = 0; byte < 8; byte++) output[offset + byte] = (uint8)((bits >> (8 * byte)) & 255);
}

fn long dynamic_tree_maximum_weight_independent_set(long* input, usz length,
    uint8* output, usz capacity) @export("dynamic_tree_maximum_weight_independent_set") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0]; long q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    int n = (int)n_value; int q = (int)q_value;
    int edge_end = 2 + n + 2 * (n - 1);
    if (length != (usz)(edge_end + 2 * q)) return -1;

    int[MAX_N] dsu; long[MAX_N] weights; bool[MAX_N][MAX_N] adjacency = zeroed;
    for (int u = 0; u < n; u++) {
        dsu[u] = u;
        weights[u] = input[2 + u];
        if (weights[u] < 0 || weights[u] > MAX_WEIGHT) return -1;
    }
    for (int e = 0; e < n - 1; e++) {
        int offset = 2 + n + 2 * e;
        long uu = input[offset]; long vv = input[offset + 1];
        if (uu < 0 || uu >= n || vv < 0 || vv >= n || uu == vv) return -1;
        int u = (int)uu; int v = (int)vv;
        int ru = find_root(&dsu[0], u); int rv = find_root(&dsu[0], v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
        adjacency[u][v] = true; adjacency[v][u] = true;
    }
    int root_set = find_root(&dsu[0], 0);
    for (int u = 1; u < n; u++) if (find_root(&dsu[0], u) != root_set) return -1;

    int[MAX_Q] update_vertex; long[MAX_Q] update_weight;
    for (int i = 0; i < q; i++) {
        int offset = edge_end + 2 * i;
        long vertex = input[offset]; long weight = input[offset + 1];
        if (vertex < 0 || vertex >= n || weight < 0 || weight > MAX_WEIGHT) return -1;
        update_vertex[i] = (int)vertex; update_weight[i] = weight;
    }
    usz output_bytes = (usz)(8 * q);
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;

    int[MAX_N] parent; int[MAX_N] order;
    for (int u = 0; u < n; u++) parent[u] = -2;
    parent[0] = -1; order[0] = 0;
    int order_count = 1;
    for (int i = 0; i < order_count; i++) {
        int u = order[i];
        for (int v = 0; v < n; v++) if (adjacency[u][v] && parent[v] == -2) {
            parent[v] = u; order[order_count] = v; order_count++;
        }
    }
    int[MAX_N] subtree; int[MAX_N] heavy;
    long[MAX_N] skip = zeroed; long[MAX_N] take;
    for (int u = 0; u < n; u++) { subtree[u] = 1; heavy[u] = -1; take[u] = weights[u]; }
    for (int i = n - 1; i > 0; i--) {
        int u = order[i]; int p = parent[u];
        subtree[p] += subtree[u];
        if (heavy[p] < 0 || subtree[u] > subtree[heavy[p]]) heavy[p] = u;
        skip[p] += max64(skip[u], take[u]); take[p] += skip[u];
    }

    int[MAX_N] head; int[MAX_N] position; int[MAX_N] tail;
    int[MAX_N] chains; int chain_count = 1; int clock = 0;
    chains[0] = 0;
    for (int u = 0; u < n; u++) tail[u] = -1;
    while (chain_count > 0) {
        chain_count--; int h = chains[chain_count]; int u = h;
        while (u >= 0) {
            head[u] = h; position[u] = clock; clock++; tail[h] = u;
            for (int v = 1; v < n; v++) if (parent[v] == u && v != heavy[u]) {
                chains[chain_count] = v; chain_count++;
            }
            u = heavy[u];
        }
    }

    Matrix[MAX_N] matrices; Matrix[2 * MAX_N] segment;
    Matrix id = identity();
    for (int i = 0; i < 2 * MAX_N; i++) segment[i] = id;
    for (int u = 0; u < n; u++) {
        long light0 = 0; long light1 = weights[u];
        for (int v = 1; v < n; v++) if (parent[v] == u && v != heavy[u]) {
            light0 += max64(skip[v], take[v]); light1 += skip[v];
        }
        matrices[u].a[0][0] = light0; matrices[u].a[0][1] = light0;
        matrices[u].a[1][0] = light1; matrices[u].a[1][1] = NEG;
        segment[MAX_N + position[u]] = matrices[u];
    }
    for (int i = MAX_N - 1; i > 0; i--) segment[i] = multiply(segment[2 * i], segment[2 * i + 1]);

    long[MAX_Q] staged;
    for (int i = 0; i < q; i++) {
        int vertex = update_vertex[i]; int h = head[vertex]; long[2] old_state; long[2] new_state;
        summary(&segment[0], &position[0], &tail[0], h, &old_state[0]);
        long delta = update_weight[i] - weights[vertex]; weights[vertex] = update_weight[i];
        matrices[vertex].a[1][0] += delta;
        set_matrix(&segment[0], position[vertex], matrices[vertex]);
        summary(&segment[0], &position[0], &tail[0], h, &new_state[0]);
        while (parent[h] != -1) {
            int p = parent[h]; int ph = head[p]; long[2] before;
            summary(&segment[0], &position[0], &tail[0], ph, &before[0]);
            long delta0 = max64(new_state[0], new_state[1]) - max64(old_state[0], old_state[1]);
            long delta1 = new_state[0] - old_state[0];
            matrices[p].a[0][0] += delta0; matrices[p].a[0][1] += delta0;
            matrices[p].a[1][0] += delta1;
            set_matrix(&segment[0], position[p], matrices[p]);
            old_state[0] = before[0]; old_state[1] = before[1];
            summary(&segment[0], &position[0], &tail[0], ph, &new_state[0]);
            h = ph;
        }
        long[2] answer; summary(&segment[0], &position[0], &tail[0], 0, &answer[0]);
        staged[i] = max64(answer[0], answer[1]);
    }
    for (int i = 0; i < q; i++) store_le(output, (usz)(8 * i), staged[i]);
    return (long)output_bytes;
}
