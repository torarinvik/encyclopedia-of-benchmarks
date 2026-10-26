// Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile.
module gbbs_biconnectivity;
const usz N = 12;
const usz M = 24;
const usz INPUT = 2 + 2 * M;

fn bool tree_edge(usz u, usz v, usz* parent) {
    return parent[u] == v || parent[v] == u;
}
fn bool critical_edge(usz u, usz v, usz* parent, bool* critical) {
    if (parent[u] == v) return critical[u];
    if (parent[v] == u) return critical[v];
    return false;
}

fn void parents_bfs(usz n, bool* adjacent, usz* parent, bool* seen) {
    usz[N] frontier = zeroed;
    usz[N] next = zeroed;
    usz[N] candidate = zeroed;
    for (usz root = 0; root < n; root += 1) {
        if (seen[root]) continue;
        usz count = 1;
        frontier[0] = root;
        parent[root] = root;
        seen[root] = true;
        while (count != 0) {
            bool[N] has = zeroed;
            for (usz i = 0; i < count; i += 1) {
                usz vertex = frontier[i];
                for (usz other = 0; other < n; other += 1) {
                    if (adjacent[vertex * N + other] && !seen[other]) {
                        if (!has[other] || vertex < candidate[other]) candidate[other] = vertex;
                        has[other] = true;
                    }
                }
            }
            usz next_count = 0;
            for (usz other = 0; other < n; other += 1) {
                if (has[other]) {
                    parent[other] = candidate[other];
                    seen[other] = true;
                    next[next_count] = other;
                    next_count += 1;
                }
            }
            for (usz i = 0; i < next_count; i += 1) frontier[i] = next[i];
            count = next_count;
        }
    }
}

fn void assign_preorder(usz n, usz* parent, usz* pn, usz* order, usz* size) {
    usz[N] stack = zeroed;
    usz global = 0;
    for (usz root = 0; root < n; root += 1) {
        if (parent[root] != root) continue;
        usz top = 0, count = 0, begin = global;
        stack[top] = root;
        top += 1;
        while (top != 0) {
            top -= 1;
            usz vertex = stack[top];
            pn[vertex] = count;
            count += 1;
            order[global] = vertex;
            global += 1;
            for (usz child = n; child > 0;) {
                child -= 1;
                if (child != vertex && parent[child] == vertex) {
                    stack[top] = child;
                    top += 1;
                }
            }
        }
        usz i = global;
        while (i > begin) {
            i -= 1;
            usz vertex = order[i];
            if (parent[vertex] != vertex) size[parent[vertex]] += size[vertex];
        }
    }
}

long gbbs_biconnectivity(long* input, usz length, char* output, usz capacity)
        @export("gbbs_biconnectivity") {
    if (input == null || length < 2 || length > INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 12 || m64 < 0 || m64 > 24 ||
        length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    bool[N * N] adjacent = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * N + v]) return -1;
        adjacent[u * N + v] = true;
        adjacent[v * N + u] = true;
    }
    if (output == null || capacity < m) return -2;
    usz[N] parent = zeroed, pn = zeroed, order = zeroed, size = zeroed;
    bool[N] seen = zeroed, critical = zeroed;
    for (usz v = 0; v < n; v += 1) { parent[v] = v; size[v] = 1; }
    parents_bfs(n, &adjacent[0], &parent[0], &seen[0]);
    assign_preorder(n, &parent[0], &pn[0], &order[0], &size[0]);
    usz[N] low = zeroed, high = zeroed;
    for (usz v = 0; v < n; v += 1) {
        low[v] = pn[v];
        high[v] = pn[v] + size[v] - 1;
    }
    for (usz edge = 0; edge < m; edge += 1) {
        usz u = (usz)input[2 + 2 * edge], v = (usz)input[3 + 2 * edge];
        if (!tree_edge(u, v, &parent[0])) {
            if (pn[u] < low[v]) low[v] = pn[u];
            else if (pn[u] > high[v]) high[v] = pn[u];
            if (pn[v] < low[u]) low[u] = pn[v];
            else if (pn[v] > high[u]) high[u] = pn[v];
        }
    }
    usz i = n;
    while (i > 0) {
        i -= 1;
        usz vertex = order[i];
        if (parent[vertex] != vertex) {
            usz p = parent[vertex];
            if (low[vertex] < low[p]) low[p] = low[vertex];
            if (high[vertex] > high[p]) high[p] = high[vertex];
        }
    }
    for (usz v = 0; v < n; v += 1) {
        usz p = parent[v];
        if (v != p && low[v] >= pn[p] && high[v] < pn[p] + size[p]) critical[v] = true;
    }
    usz[N] component = zeroed, queue = zeroed;
    for (usz v = 0; v < n; v += 1) component[v] = N;
    for (usz root = 0; root < n; root += 1) {
        if (component[root] != N) continue;
        usz head = 0, tail = 0;
        component[root] = root;
        queue[tail] = root;
        tail += 1;
        while (head < tail) {
            usz vertex = queue[head];
            head += 1;
            for (usz other = 0; other < n; other += 1) {
                if (adjacent[vertex * N + other] &&
                    !critical_edge(vertex, other, &parent[0], &critical[0]) &&
                    component[other] == N) {
                    component[other] = root;
                    queue[tail] = other;
                    tail += 1;
                }
            }
        }
    }
    usz[M] raw = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        usz u = (usz)input[2 + 2 * edge], v = (usz)input[3 + 2 * edge];
        if (parent[u] == v && critical[u]) raw[edge] = component[u];
        else if (parent[v] == u && critical[v]) raw[edge] = component[v];
        else raw[edge] = component[u];
    }
    for (usz edge = 0; edge < m; edge += 1) {
        usz label = m;
        for (usz other = 0; other < m; other += 1) {
            if (raw[other] == raw[edge] && other < label) label = other;
        }
        output[edge] = (char)label;
    }
    return (long)m;
}
