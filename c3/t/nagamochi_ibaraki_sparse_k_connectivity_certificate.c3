module nagamochi_ibaraki_sparse_k_connectivity_certificate;
const usz MAX_N = 8; const usz MAX_M = 28; const usz MAX_INPUT = 60;

fn void put(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i += 1) { out[at+i] = (char)(bits & 255); bits >>= 8; }
}

fn long nagamochi_ibaraki_sparse_k_connectivity_certificate(long* input, usz len,
        char* output, usz cap) @export("nagamochi_ibaraki_sparse_k_connectivity_certificate") {
    if (input == null || len < 3 || len > MAX_INPUT) return -1;
    long n0 = input[0]; long m0 = input[1]; long k0 = input[2];
    if (n0 < 3 || n0 > 8 || m0 < 0 || m0 > 28 || k0 < 1 || k0 > 3
            || len != 3 + 2 * (usz)m0) return -1;
    usz n = (usz)n0; usz m = (usz)m0; usz k = (usz)k0;
    usz[MAX_M] u = zeroed; usz[MAX_M] v = zeroed;
    usz[MAX_N][MAX_N] incident = zeroed; usz[MAX_N] degree = zeroed;
    for (usz e = 0; e < m; e += 1) {
        long a = input[3 + 2*e]; long b = input[4 + 2*e];
        if (a < 0 || a >= b || b >= n0) return -1;
        u[e] = (usz)a; v[e] = (usz)b;
        for (usz j = 0; j < e; j += 1) if (u[j] == u[e] && v[j] == v[e]) return -1;
        incident[u[e]][degree[u[e]]] = e; degree[u[e]] += 1;
        incident[v[e]][degree[v[e]]] = e; degree[v[e]] += 1;
    }
    usz bytes = 8 * (m + 1);
    if (output == null || cap < bytes) return -2;
    usz[MAX_N] rank = zeroed; usz[MAX_M] layer = zeroed;
    bool[MAX_N] scanned_vertex = zeroed; bool[MAX_M] scanned_edge = zeroed;
    for (usz step = 0; step < n; step += 1) {
        usz x = n;
        for (usz vertex = 0; vertex < n; vertex += 1)
            if (!scanned_vertex[vertex] && (x == n || rank[vertex] > rank[x])) x = vertex;
        for (usz slot = 0; slot < degree[x]; slot += 1) {
            usz e = incident[x][slot];
            if (scanned_edge[e]) continue;
            usz y = u[e] == x ? v[e] : u[e];
            layer[e] = rank[y] + 1;
            if (rank[x] == rank[y]) rank[x] += 1;
            rank[y] += 1;
            scanned_edge[e] = true;
        }
        scanned_vertex[x] = true;
    }
    put(output, 0, (long)m);
    for (usz e = 0; e < m; e += 1) put(output, 8*(e+1), (long)(layer[e] <= k ? layer[e] : 0));
    return (long)bytes;
}
