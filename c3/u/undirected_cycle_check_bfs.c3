module undirected_cycle_check_bfs;

fn long undirected_cycle_check_bfs(long* input, usz length) @export("undirected_cycle_check_bfs") {
    if (input == null || length < 2 || length > 514 || input[0] < 0 || input[0] > 32 || input[1] < 0 || input[1] > 256) return -1;
    usz n = (usz)input[0]; usz m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;
    bool[32][32] adjacent = zeroed; bool[32] visited = zeroed;
    for (usz i = 0; i < m; i++) {
        long a = input[2 + 2 * i]; long b = input[3 + 2 * i];
        if (a < 0 || b < 0 || a >= (long)n || b >= (long)n) return -1;
        usz u = (usz)a; usz v = (usz)b;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true; adjacent[v][u] = true;
    }
    usz[32] queue = zeroed; usz[32] parent = zeroed;
    for (usz root = 0; root < n; root++) {
        if (visited[root]) continue;
        usz head = 0; usz tail = 1; queue[0] = root; parent[root] = n; visited[root] = true;
        while (head < tail) {
            usz u = queue[head++];
            for (usz v = 0; v < n; v++) if (adjacent[u][v]) {
                if (!visited[v]) { visited[v] = true; parent[v] = u; queue[tail++] = v; }
                else if (v != parent[u]) return 1;
            }
        }
    }
    return 0;
}
