module karger_contraction_trial;

fn usz root(long* parent, usz vertex) {
    while (parent[vertex] != (long)vertex) vertex = (usz)parent[vertex];
    return vertex;
}

fn long karger_contraction_trial(long* input, usz length) @export("karger_contraction_trial") {
    if (input == null || length < 2 || length > 57) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 2 || n64 > 8 || m64 < 1 || m64 > 24) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + 2 * m + n - 2) return -1;
    long[24] u = zeroed, v = zeroed;
    long[8] parent = zeroed;
    for (usz i = 0; i < n; i += 1) parent[i] = (long)i;
    for (usz i = 0; i < m; i += 1) {
        long a = input[2 + 2 * i], b = input[3 + 2 * i];
        if (a < 0 || b < 0 || a >= n64 || b >= n64 || a == b) return -1;
        u[i] = a; v[i] = b;
        usz left = root(&parent[0], (usz)a), right = root(&parent[0], (usz)b);
        parent[left] = (long)right;
    }
    usz initial = root(&parent[0], 0);
    for (usz i = 1; i < n; i += 1) if (root(&parent[0], i) != initial) return -1;
    for (usz i = 0; i < n; i += 1) parent[i] = (long)i;
    for (usz step = 0; step < n - 2; step += 1) {
        long live = 0;
        for (usz i = 0; i < m; i += 1) if (root(&parent[0], (usz)u[i]) != root(&parent[0], (usz)v[i])) live += 1;
        long rank = input[2 + 2 * m + step];
        if (rank < 0 || rank >= live) return -1;
        for (usz i = 0; i < m; i += 1) {
            usz left = root(&parent[0], (usz)u[i]), right = root(&parent[0], (usz)v[i]);
            if (left == right) continue;
            if (rank == 0) { parent[left] = (long)right; break; }
            rank -= 1;
        }
    }
    long cut = 0;
    for (usz i = 0; i < m; i += 1) if (root(&parent[0], (usz)u[i]) != root(&parent[0], (usz)v[i])) cut += 1;
    return cut;
}
