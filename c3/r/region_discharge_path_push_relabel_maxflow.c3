module region_discharge_path_push_relabel_maxflow;

const int NMAX = 8, MMAX = 12, KMAX = 4, INPUT_MAX = 50;

fn bool ard_reaches(int n, bool* allowed, long* residual, int start, bool* target) {
    if (target[start]) return true;
    bool[NMAX] seen = zeroed;
    int[NMAX] queue = zeroed;
    int head = 0, tail = 0;
    seen[start] = true; queue[tail++] = start;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < n; v++) {
            if (seen[v] || !allowed[u * NMAX + v] || residual[u * NMAX + v] <= 0) continue;
            if (target[v]) return true;
            seen[v] = true; queue[tail++] = v;
        }
    }
    return false;
}

fn int ard_find_path(int n, bool* in_region, bool* allowed, long* residual,
                     bool* target, long* excess, int* parent) {
    int[NMAX] queue = zeroed;
    for (int v = 0; v < NMAX; v++) parent[v] = -1;
    int head = 0, tail = 0;
    for (int v = 0; v < n; v++) if (in_region[v] && excess[v] > 0) {
        parent[v] = v; queue[tail++] = v;
    }
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < n; v++) {
            if (parent[v] >= 0 || !allowed[u * NMAX + v] || residual[u * NMAX + v] <= 0) continue;
            parent[v] = u;
            if (target[v]) return v;
            queue[tail++] = v;
        }
    }
    return -1;
}

fn long ard_discharge(int n, int region_id, int source, int sink, int boundary_count,
                      int* regions, bool* boundary_by_region, long* global_residual,
                      long* residual, long* excess, int* labels, long flow_value) {
    bool[NMAX] in_region = zeroed, external = zeroed, inside_terminal = zeroed;
    bool[NMAX * NMAX] allowed = zeroed;
    long[NMAX * NMAX] local = zeroed;
    for (int v = 0; v < n; v++) {
        in_region[v] = v != source && v != sink && regions[v] == region_id;
        external[v] = boundary_by_region[region_id * NMAX + v];
        inside_terminal[v] = in_region[v] || v == source || v == sink;
    }
    for (int u = 0; u < n; u++) for (int v = 0; v < n; v++) {
        allowed[u * NMAX + v] = (inside_terminal[u] && inside_terminal[v]) ||
            (in_region[u] && external[v]) || (external[u] && in_region[v]);
        if (allowed[u * NMAX + v] && !(external[u] && in_region[v]))
            local[u * NMAX + v] = global_residual[u * NMAX + v];
    }
    long flow = flow_value;
    for (int stage = 0; stage <= boundary_count; stage++) {
        bool[NMAX] target = zeroed; target[sink] = true;
        for (int v = 0; v < n; v++) if (external[v] && labels[v] < stage) target[v] = true;
        while (true) {
            int[NMAX] parent = zeroed;
            int finish = ard_find_path(n, &in_region[0], &allowed[0], &local[0],
                                       &target[0], excess, &parent[0]);
            if (finish < 0) break;
            int[NMAX] path = zeroed;
            int path_len = 0, v = finish;
            while (true) { path[path_len++] = v; if (parent[v] == v) break; v = parent[v]; }
            int start = path[path_len - 1];
            long amount = excess[start];
            for (int i = path_len - 1; i > 0; i--) {
                int u = path[i], v = path[i - 1];
                if (local[u * NMAX + v] < amount) amount = local[u * NMAX + v];
            }
            for (int i = path_len - 1; i > 0; i--) {
                int u = path[i], v = path[i - 1];
                local[u * NMAX + v] -= amount; local[v * NMAX + u] += amount;
                residual[u * NMAX + v] -= amount; residual[v * NMAX + u] += amount;
            }
            excess[start] -= amount;
            if (finish == sink) flow += amount; else excess[finish] += amount;
        }
    }
    for (int u = 0; u < n; u++) if (in_region[u]) {
        int next_label = boundary_count;
        for (int stage = 0; stage <= boundary_count; stage++) {
            bool[NMAX] target = zeroed; target[sink] = true;
            for (int v = 0; v < n; v++) if (external[v] && labels[v] < stage) target[v] = true;
            if (ard_reaches(n, &allowed[0], &local[0], u, &target[0])) { next_label = stage; break; }
        }
        if (next_label > labels[u]) labels[u] = next_label;
    }
    return flow;
}

fn long region_discharge_path_push_relabel_maxflow(long* input, usz length)
    @export("region_discharge_path_push_relabel_maxflow") {
    if (input == null || length < 5 || length > INPUT_MAX) return -1;
    long rn = input[0], rm = input[1], rk = input[2], rs = input[3], rt = input[4];
    if (rn < 4 || rn > NMAX || rm < 1 || rm > MMAX || rk < 2 || rk > KMAX || rk > rn - 2 ||
        rs < 0 || rs >= rn || rt < 0 || rt >= rn || rs == rt ||
        length != 5 + (usz)rn + 3 * (usz)rm) return -1;
    int n = (int)rn, m = (int)rm, k = (int)rk, source = (int)rs, sink = (int)rt;
    int[NMAX] regions = zeroed;
    bool[KMAX] seen = zeroed;
    bool[KMAX * NMAX] boundary_by_region = zeroed;
    bool[NMAX] boundary = zeroed;
    long[NMAX * NMAX] capacity = zeroed, residual = zeroed;
    long[NMAX] excess = zeroed;
    int[NMAX] labels = zeroed;
    usz at = 5;
    for (int v = 0; v < n; v++) {
        long raw = input[at++];
        if (v == source || v == sink) { if (raw != -1) return -1; regions[v] = -1; }
        else { if (raw < 0 || raw >= rk) return -1; regions[v] = (int)raw; seen[regions[v]] = true; }
    }
    for (int b = 0; b < k; b++) if (!seen[b]) return -1;
    for (int e = 0; e < m; e++) {
        long ru = input[at++], rv = input[at++], cap = input[at++];
        if (ru < 0 || ru >= rn || rv < 0 || rv >= rn || ru == rv || rv == rs || ru == rt || cap < 0 || cap > 7) return -1;
        int u = (int)ru, v = (int)rv;
        capacity[u * NMAX + v] += cap;
        if (cap > 0 && regions[u] >= 0 && regions[v] >= 0 && regions[u] != regions[v]) {
            boundary[u] = true; boundary[v] = true;
            boundary_by_region[regions[u] * NMAX + v] = true;
            boundary_by_region[regions[v] * NMAX + u] = true;
        }
    }
    int boundary_count = 0;
    for (int v = 0; v < n; v++) if (boundary[v]) boundary_count++;
    if (boundary_count < 2) return -1;
    for (int i = 0; i < NMAX * NMAX; i++) residual[i] = capacity[i];
    long flow = 0;
    for (int v = 0; v < n; v++) {
        long amount = residual[source * NMAX + v];
        if (amount > 0) {
            residual[source * NMAX + v] = 0;
            residual[v * NMAX + source] += amount;
            if (v == sink) flow += amount; else excess[v] += amount;
        }
    }
    labels[source] = boundary_count;
    int sweep_limit = 2 * boundary_count * boundary_count + 1;
    for (int sweep = 0; sweep < sweep_limit; sweep++) {
        for (int b = 0; b < k; b++)
            flow = ard_discharge(n, b, source, sink, boundary_count, &regions[0],
                                 &boundary_by_region[0], &residual[0], &residual[0],
                                 &excess[0], &labels[0], flow);
        bool active = false;
        for (int v = 0; v < n; v++)
            if (v != source && v != sink && excess[v] > 0 && labels[v] < boundary_count) active = true;
        if (!active) return flow;
    }
    return -1;
}
