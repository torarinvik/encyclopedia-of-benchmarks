module ida_star_graph;

struct Search {
    int n, goal, bound, next_bound;
    int[12] heuristic;
    uint[12] edges;
}

fn int visit(Search* s, int u, int depth, uint path) {
    int score = depth + s.heuristic[u];
    if (score > s.bound) {
        if (score < s.next_bound) s.next_bound = score;
        return -1;
    }
    if (u == s.goal) return depth;
    for (int v = 0; v < s.n; v++) {
        uint bit = 1u << v;
        if ((s.edges[u] & bit) != 0 && (path & bit) == 0) {
            int found = visit(s, v, depth + 1, path | bit);
            if (found >= 0) return found;
        }
    }
    return -1;
}

fn long ida_star_graph(long* values, usz length) @export("ida_star_graph") {
    if (values == null || length < 5 || length > 112) return long.min;
    long n = values[0], m = values[1], start = values[2], goal = values[3];
    if (n < 1 || n > 12 || m < 0 || m > 48 || start < 0 || start >= n ||
        goal < 0 || goal >= n || length != (usz)(4+n+2*m)) return long.min;
    Search s = {};
    s.n = (int)n; s.goal = (int)goal;
    for (int i = 0; i < s.n; i++) {
        if (values[4+i] < 0 || values[4+i] >= n) return long.min;
        s.heuristic[i] = (int)values[4+i];
    }
    if (s.heuristic[s.goal] != 0) return long.min;
    for (int i = 0; i < m; i++) {
        long u = values[4+n+2*i], v = values[5+n+2*i];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return long.min;
        uint bit = 1u << (uint)v;
        if ((s.edges[u] & bit) != 0 || s.heuristic[u] > s.heuristic[v]+1) return long.min;
        s.edges[u] |= bit;
    }
    s.bound = s.heuristic[start];
    for (;;) {
        s.next_bound = 1000;
        int found = visit(&s, (int)start, 0, 1u << (uint)start);
        if (found >= 0) return found;
        if (s.next_bound == 1000) return -1;
        s.bound = s.next_bound;
    }
}
