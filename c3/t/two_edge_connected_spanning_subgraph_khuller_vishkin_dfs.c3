module two_edge_connected_spanning_subgraph_khuller_vishkin_dfs;
const usz MAX_N = 8; const usz MAX_M = 28; const usz MAX_INPUT = 59;
fn void put(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i += 1) { out[at+i] = (char)(bits & 255); bits >>= 8; }
}
fn bool connected(usz n, usz m, usz* u, usz* v, long skip) {
    bool[MAX_N] seen = zeroed; usz[MAX_N] q = zeroed;
    usz head = 0; usz tail = 1; q[0] = 0; seen[0] = true;
    while (head < tail) {
        usz x = q[head]; head += 1;
        for (usz e = 0; e < m; e += 1) {
            if ((long)e == skip) continue;
            usz y = MAX_N;
            if (u[e] == x) y = v[e]; else if (v[e] == x) y = u[e];
            if (y < n && !seen[y]) { seen[y] = true; q[tail] = y; tail += 1; }
        }
    }
    for (usz i = 0; i < n; i += 1) if (!seen[i]) return false;
    return true;
}
fn bool earlier(usz a, usz b, usz* disc) { return disc[a] < disc[b]; }
fn long two_edge_connected_spanning_subgraph_khuller_vishkin_dfs(long* input, usz len, char* output, usz cap) @export("two_edge_connected_spanning_subgraph_khuller_vishkin_dfs") {
    if (input == null || len < 2 || len > MAX_INPUT) return -1;
    long n0 = input[0]; long m0 = input[1];
    if (n0 < 3 || n0 > 8 || m0 < 3 || m0 > 28 || len != 2 + 2*(usz)m0) return -1;
    usz n = (usz)n0; usz m = (usz)m0; usz[MAX_M] u = zeroed; usz[MAX_M] v = zeroed;
    for (usz e = 0; e < m; e += 1) {
        long a = input[2+2*e]; long b = input[3+2*e];
        if (a < 0 || a >= b || b >= n0) return -1;
        u[e] = (usz)a; v[e] = (usz)b;
        for (usz j = 0; j < e; j += 1) if (u[j] == u[e] && v[j] == v[e]) return -1;
    }
    if (!connected(n, m, &u[0], &v[0], -1)) return -1;
    for (usz e = 0; e < m; e += 1) if (!connected(n, m, &u[0], &v[0], (long)e)) return -1;

    usz[MAX_N] state = zeroed; usz[MAX_N] disc = zeroed; usz[MAX_N] low = zeroed;
    usz[MAX_N] low_h = zeroed; usz[MAX_N] savior = zeroed; bool[MAX_M] selected = zeroed;
    usz[MAX_N] stack_v = zeroed; usz[MAX_N] stack_parent = zeroed; usz[MAX_N] stack_cursor = zeroed;
    usz tick = 1; usz top = 1; state[0] = 1; disc[0] = 0; low[0] = 0; low_h[0] = 0; savior[0] = 0;
    stack_v[0] = 0; stack_parent[0] = MAX_N; stack_cursor[0] = 0;
    while (top > 0) {
        usz frame = top - 1; usz x = stack_v[frame]; usz parent = stack_parent[frame];
        if (stack_cursor[frame] < m) {
            usz e = stack_cursor[frame]; stack_cursor[frame] += 1; usz y = MAX_N;
            if (u[e] == x) y = v[e]; else if (v[e] == x) y = u[e];
            if (y == MAX_N) continue;
            if (state[y] == 0) {
                selected[e] = true; state[y] = 1; disc[y] = tick; tick += 1;
                low[y] = y; low_h[y] = y; savior[y] = y;
                stack_v[top] = y; stack_parent[top] = x; stack_cursor[top] = 0; top += 1;
            } else if (state[y] == 1 && y != parent && earlier(y, low[x], &disc[0])) {
                low[x] = y; savior[x] = x;
            }
            continue;
        }
        state[x] = 2;
        if (parent < n && low_h[x] == x) {
            usz a = savior[x]; usz b = low[x]; usz lo = a < b ? a : b; usz hi = a < b ? b : a;
            for (usz e = 0; e < m; e += 1) if (u[e] == lo && v[e] == hi) { selected[e] = true; break; }
            low_h[x] = low[x];
        }
        top -= 1;
        if (parent < n) {
            if (earlier(low[x], low[parent], &disc[0])) { low[parent] = low[x]; savior[parent] = savior[x]; }
            if (earlier(low_h[x], low_h[parent], &disc[0])) low_h[parent] = low_h[x];
        }
    }
    usz count = 0; for (usz e = 0; e < m; e += 1) if (selected[e]) count += 1;
    usz bytes = 8 * (1 + 2 * count); if (output == null || cap < bytes) return -2;
    put(output, 0, (long)count); usz at = 8;
    for (usz a = 0; a < n; a += 1) for (usz b = a+1; b < n; b += 1) for (usz e = 0; e < m; e += 1)
        if (selected[e] && u[e] == a && v[e] == b) { put(output, at, (long)a); put(output, at+8, (long)b); at += 16; }
    return (long)bytes;
}
