module approximating_diameter_bfs;

fn void put_i64(uint8* output, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[b] = (uint8)(bits >> (8 * b));
}

fn long approximating_diameter_bfs(long* input, usz length, uint8* output, usz capacity) @export("approximating_diameter_bfs") {
    if (input == null || length < 2 || length > 242) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 16 || m0 < 0 || m0 > 120 || length != (usz)(2 + 2 * m0)) return -1;
    usz n = (usz)n0, m = (usz)m0;
    bool[16][16] adj;
    for (usz i = 0; i < m; i++) {
        long u0 = input[2 + 2*i], v0 = input[3 + 2*i];
        if (u0 < 0 || v0 <= u0 || v0 >= n0) return -1;
        usz u = (usz)u0, v = (usz)v0;
        if (adj[u][v]) return -1;
        adj[u][v] = true; adj[v][u] = true;
    }
    long[16] dist;
    usz[16] queue;
    for (usz i = 0; i < n; i++) dist[i] = -1;
    dist[0] = 0; queue[0] = 0; usz head = 0, tail = 1;
    while (head < tail) {
        usz u = queue[head]; head++;
        for (usz v = 0; v < n; v++) if (adj[u][v] && dist[v] < 0) {
            dist[v] = dist[u] + 1; queue[tail] = v; tail++;
        }
    }
    if (tail != n) return -1;
    long estimate = 0;
    for (usz i = 0; i < n; i++) if (dist[i] > estimate) estimate = dist[i];
    if (output == null || capacity < 8) return -2;
    put_i64(output, estimate);
    return 8;
}
