module khuller_raghavachari_three_edge_connected_spanning_subgraph;
const usz MAX_N = 8; const usz MAX_M = 28; const usz MAX_INPUT = 59;

fn void put(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { out[at + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long khuller_raghavachari_three_edge_connected_spanning_subgraph(long* input,
        usz len, char* output, usz cap) @export("khuller_raghavachari_three_edge_connected_spanning_subgraph") {
    if (input == null || len < 2 || len > MAX_INPUT) return -1;
    long n0 = input[0]; long m0 = input[1];
    if (n0 < 4 || n0 > 8 || m0 < 6 || m0 > 28 || len != 2 + 2 * (usz)m0) return -1;
    usz n = (usz)n0; usz m = (usz)m0;
    usz[MAX_M] u = zeroed; usz[MAX_M] v = zeroed;
    for (usz e = 0; e < m; e += 1) {
        long a = input[2 + 2*e]; long b = input[3 + 2*e];
        if (a < 0 || a >= b || b >= n0) return -1;
        u[e] = (usz)a; v[e] = (usz)b;
        for (usz prior = 0; prior < e; prior += 1)
            if (u[prior] == u[e] && v[prior] == v[e]) return -1;
    }
    usz full = ((usz)1 << n) - 1;
    for (usz side = 1; side < full; side += 1) {
        if ((side & 1) == 0) continue;
        usz cut = 0;
        for (usz e = 0; e < m; e += 1)
            if (((side >> u[e]) & 1) != ((side >> v[e]) & 1)) cut += 1;
        if (cut < 3) return -1;
    }

    bool[MAX_M] selected = zeroed;
    usz[MAX_N] state = zeroed; usz[MAX_N] discovery = zeroed; usz[MAX_N] finish = zeroed;
    usz[MAX_N] parent = zeroed; usz[MAX_N] parent_edge = zeroed;
    usz[MAX_N] postorder = zeroed; usz[MAX_N] stack_vertex = zeroed; usz[MAX_N] stack_slot = zeroed;
    usz post_count = 0; usz clock = 1; usz top = 1;
    state[0] = 1; discovery[0] = 0; parent[0] = n; parent_edge[0] = m; stack_vertex[0] = 0;
    while (top > 0) {
        usz frame = top - 1; usz x = stack_vertex[frame];
        if (stack_slot[frame] < m) {
            usz e = stack_slot[frame]; stack_slot[frame] += 1;
            usz y = n;
            if (u[e] == x) y = v[e]; else if (v[e] == x) y = u[e];
            if (y == n || state[y] != 0) continue;
            selected[e] = true; state[y] = 1; parent[y] = x; parent_edge[y] = e;
            discovery[y] = clock; clock += 1;
            stack_vertex[top] = y; stack_slot[top] = 0; top += 1;
            continue;
        }
        state[x] = 2; finish[x] = clock;
        if (parent_edge[x] < m) { postorder[post_count] = parent_edge[x]; post_count += 1; }
        top -= 1;
    }

    usz p = 0;
    while (p < post_count) {
        usz tree_edge = postorder[p]; p += 1;
        usz child = parent_edge[u[tree_edge]] == tree_edge ? u[tree_edge] : v[tree_edge];
        usz upper = parent[child];
        bool separated = false;
        usz removed = 0;
        while (removed < m && !separated) {
            if (selected[removed]) {
                bool[MAX_N] seen = zeroed; usz[MAX_N] queue = zeroed;
                usz head = 0; usz tail = 1; seen[upper] = true; queue[0] = upper;
                while (head < tail) {
                    usz current = queue[head]; head += 1;
                    usz e = 0;
                    while (e < m) {
                        if (selected[e] && e != removed) {
                            usz next = n;
                            if (u[e] == current) next = v[e]; else if (v[e] == current) next = u[e];
                            if (next < n && !seen[next]) { seen[next] = true; queue[tail] = next; tail += 1; }
                        }
                        e += 1;
                    }
                }
                separated = !seen[child];
            }
            removed += 1;
        }
        if (!separated) continue;
        usz candidate = m; usz earliest = n;
        usz e = 0;
        while (e < m) {
            if (!selected[e]) {
                bool u_inside = discovery[child] <= discovery[u[e]] && discovery[u[e]] < finish[child];
                bool v_inside = discovery[child] <= discovery[v[e]] && discovery[v[e]] < finish[child];
                if (u_inside != v_inside) {
                    usz ancestor = u_inside ? v[e] : u[e];
                    if (discovery[ancestor] < earliest) { earliest = discovery[ancestor]; candidate = e; }
                }
            }
            e += 1;
        }
        if (candidate == m) return -1;
        selected[candidate] = true;
    }

    usz[MAX_N] leader = zeroed;
    usz vertex = 0;
    while (vertex < n) { leader[vertex] = vertex; vertex += 1; }
    usz e = 0;
    while (e < m) {
        if (!selected[e]) {
            usz a = u[e]; usz b = v[e];
            while (leader[a] != a) { leader[a] = leader[leader[a]]; a = leader[a]; }
            while (leader[b] != b) { leader[b] = leader[leader[b]]; b = leader[b]; }
            if (a != b) { leader[b] = a; selected[e] = true; }
        }
        e += 1;
    }
    usz count = 0;
    for (usz edge = 0; edge < m; edge += 1) if (selected[edge]) count += 1;
    usz bytes = 8 * (1 + 2 * count);
    if (output == null || cap < bytes) return -2;
    put(output, 0, (long)count);
    usz slot = 0;
    for (usz edge = 0; edge < m; edge += 1) if (selected[edge]) {
        put(output, 8 * (1 + 2*slot), (long)u[edge]);
        put(output, 8 * (2 + 2*slot), (long)v[edge]);
        slot += 1;
    }
    return (long)bytes;
}
