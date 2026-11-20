module wilson_uniform_spanning_tree;

const usz MAX_N = 8;
const usz MAX_EDGES = 28;
const usz WALK_LIMIT = 64;
const usz MAX_INPUT = 4 + 2 * MAX_EDGES + WALK_LIMIT * (MAX_N - 1);

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long wilson_uniform_spanning_tree(long* input, usz length, char* output, usz capacity)
        @export("wilson_uniform_spanning_tree") {
    if (input == null || length < 4 || length > MAX_INPUT + 1) return -1;
    long n0 = input[0], m0 = input[1], root0 = input[2];
    if (n0 < 1 || n0 > (long)MAX_N || m0 < 0 || m0 > (long)MAX_EDGES) return -1;
    usz n = (usz)n0, m = (usz)m0;
    if (root0 < 0 || root0 >= n0) return -1;
    usz root = (usz)root0, q_at = 3 + 2 * m;
    if (length <= q_at) return -1;
    long q0 = input[q_at];
    if (q0 < 0 || q0 > (long)(WALK_LIMIT * (n - 1))) return -1;
    usz q = (usz)q0;
    if (length != q_at + 1 + q) return -1;

    usz[MAX_N][MAX_N - 1] neighbors;
    usz[MAX_N] degree;
    for (usz v = 0; v < MAX_N; v++) degree[v] = 0;
    long prev_u = -1, prev_v = -1;
    for (usz e = 0; e < m; e++) {
        long u0 = input[3 + 2 * e], v0 = input[4 + 2 * e];
        if (u0 < 0 || u0 >= v0 || v0 >= n0) return -1;
        if (e > 0 && (u0 < prev_u || (u0 == prev_u && v0 <= prev_v))) return -1;
        prev_u = u0; prev_v = v0;
        usz u = (usz)u0, v = (usz)v0;
        neighbors[u][degree[u]++] = v;
        neighbors[v][degree[v]++] = u;
    }
    for (usz i = 0; i < q; i++) if (input[q_at + 1 + i] < 0 || input[q_at + 1 + i] > (long)(MAX_N - 2)) return -1;

    bool[MAX_N] seen;
    usz[MAX_N] queue;
    for (usz i = 0; i < MAX_N; i++) seen[i] = false;
    usz head = 0, tail = 0;
    seen[root] = true; queue[tail++] = root;
    while (head < tail) {
        usz at = queue[head++];
        for (usz k = 0; k < degree[at]; k++) {
            usz to = neighbors[at][k];
            if (!seen[to]) { seen[to] = true; queue[tail++] = to; }
        }
    }
    for (usz i = 0; i < n; i++) if (!seen[i]) return -1;

    bool[MAX_N] in_tree;
    long[MAX_N] successor;
    for (usz i = 0; i < MAX_N; i++) { in_tree[i] = false; successor[i] = -1; }
    in_tree[root] = true;
    usz cursor = 0;
    for (usz start = 0; start < n; start++) {
        if (in_tree[start]) continue;
        usz current = start, steps = 0;
        while (!in_tree[current]) {
            if (steps >= WALK_LIMIT || cursor >= q) return -1;
            usz choice = (usz)input[q_at + 1 + cursor];
            if (choice >= degree[current]) return -1;
            successor[current] = (long)neighbors[current][choice];
            current = (usz)successor[current];
            cursor++; steps++;
        }
        current = start;
        while (!in_tree[current]) { in_tree[current] = true; current = (usz)successor[current]; }
    }
    if (cursor != q) return -1;

    usz required = 16 * (n - 1);
    if ((required > 0 && output == null) || capacity < required) return -2;
    usz offset = 0;
    for (usz child = 0; child < n; child++) {
        if (child == root) continue;
        write_i64(output, offset, (long)child); offset += 8;
        write_i64(output, offset, successor[child]); offset += 8;
    }
    return (long)required;
}
