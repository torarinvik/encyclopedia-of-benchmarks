// Independently authored draft; not compiled or run.
module karger_stein_recursive_contraction;

struct KsGraph {
    usz n, m, q, position;
    usz[32] left, right;
    long[64] tape;
}

fn usz ks_root(usz* parent, usz vertex) {
    while (parent[vertex] != vertex) vertex = parent[vertex];
    return vertex;
}

fn long ks_solve(KsGraph* graph, usz* parent, usz components) {
    if (components <= 6) {
        usz[12] index = zeroed;
        usz count = 0;
        for (usz i = 0; i < graph.n; i++) if (parent[i] == i) index[i] = count++;
        long best = (long)graph.m + 1;
        for (usz mask = 0; mask < (((usz)1 << (components-1))-1); mask++) {
            usz side = (mask << 1) | 1;
            long cut = 0;
            for (usz e = 0; e < graph.m; e++) {
                usz a = index[ks_root(parent, graph.left[e])];
                usz b = index[ks_root(parent, graph.right[e])];
                if (((side >> a) & 1) != ((side >> b) & 1)) cut++;
            }
            if (cut < best) best = cut;
        }
        return best;
    }
    usz[13] targets = {0,0,0,0,0,0,0,6,7,8,9,9,10};
    long best = (long)graph.m + 1;
    for (int branch = 0; branch < 2; branch++) {
        usz[12] next = zeroed;
        for (usz i = 0; i < graph.n; i++) next[i] = parent[i];
        for (usz remaining = components; remaining > targets[components]; remaining--) {
            long live = 0;
            for (usz e = 0; e < graph.m; e++)
                if (ks_root(&next[0], graph.left[e]) != ks_root(&next[0], graph.right[e])) live++;
            if (graph.position >= graph.q) return -1;
            long rank = graph.tape[graph.position++];
            if (rank < 0 || rank >= live) return -1;
            for (usz e = 0; e < graph.m; e++) {
                usz a = ks_root(&next[0], graph.left[e]), b = ks_root(&next[0], graph.right[e]);
                if (a == b) continue;
                if (rank == 0) { next[b] = a; break; }
                rank--;
            }
        }
        long value = ks_solve(graph, &next[0], targets[components]);
        if (value < 0) return -1;
        if (value < best) best = value;
    }
    return best;
}

fn long karger_stein_recursive_contraction(long* input, usz length)
    @export("karger_stein_recursive_contraction") {
    if (input == null || length < 3 || length > 132) return -1;
    if (input[0] < 2 || input[0] > 12 || input[1] < 1 || input[1] > 32 || input[2] < 0 || input[2] > 64) return -1;
    KsGraph graph = zeroed;
    graph.n = (usz)input[0]; graph.m = (usz)input[1]; graph.q = (usz)input[2];
    if (length != 3 + 2*graph.m + graph.q) return -1;
    usz[12] parent = zeroed;
    for (usz i = 0; i < graph.n; i++) parent[i] = i;
    for (usz i = 0; i < graph.m; i++) {
        long u = input[3+2*i], v = input[4+2*i];
        if (u < 0 || v < 0 || u >= (long)graph.n || v >= (long)graph.n || u == v) return -1;
        graph.left[i] = (usz)u; graph.right[i] = (usz)v;
        usz a = ks_root(&parent[0], (usz)u), b = ks_root(&parent[0], (usz)v);
        parent[b] = a;
    }
    usz initial = ks_root(&parent[0], 0);
    for (usz i = 1; i < graph.n; i++) if (ks_root(&parent[0], i) != initial) return -1;
    for (usz i = 0; i < graph.n; i++) parent[i] = i;
    for (usz i = 0; i < graph.q; i++) graph.tape[i] = input[3+2*graph.m+i];
    long value = ks_solve(&graph, &parent[0], graph.n);
    if (value < 0 || graph.position != graph.q) return -1;
    return value;
}
