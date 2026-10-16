module edmonds_blossom_algorithm;
const usz N = 20;
fn long edmonds_blossom_algorithm(long* input, usz length) @export("edmonds_blossom_algorithm") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 20 || input[1] < 0 || input[1] > 190) return -1;
    usz n = (usz)input[0]; usz m = (usz)input[1]; if (length != 2 + 2 * m) return -1;
    bool[N * N] graph; long[N] match; long[N] parent; long[N] base; bool[N] used; bool[N] blossom; long[N] queue;
    for (usz i = 0; i < N; i++) { match[i] = -1; for (usz j = 0; j < N; j++) graph[i * N + j] = false; }
    for (usz i = 0; i < m; i++) { long a = input[2 + 2 * i]; long b = input[3 + 2 * i]; if (a < 0 || b < 0 || (usz)a >= n || (usz)b >= n || a == b) return -1; graph[(usz)a * N + (usz)b] = true; graph[(usz)b * N + (usz)a] = true; }
    long answer = 0;
    for (usz root = 0; root < n; root++) {
        if (match[root] != -1) continue;
        for (usz i = 0; i < n; i++) { used[i] = false; parent[i] = -1; base[i] = (long)i; }
        usz head = 0; usz tail = 0; queue[tail++] = (long)root; used[root] = true; long endpoint = -1;
        while (head < tail && endpoint == -1) {
            long vv = queue[head++]; usz v = (usz)vv;
            for (usz uu = 0; uu < n; uu++) {
                long u = (long)uu;
                if (!graph[v * N + uu] || base[v] == base[uu] || match[v] == u) continue;
                if (u == (long)root || (match[uu] != -1 && parent[(usz)match[uu]] != -1)) {
                    bool[N] path; for (usz i = 0; i < n; i++) path[i] = false;
                    long x = vv; long y = u;
                    while (true) { x = base[(usz)x]; path[(usz)x] = true; if (match[(usz)x] == -1) break; x = parent[(usz)match[(usz)x]]; }
                    while (!path[(usz)base[(usz)y]]) y = parent[(usz)match[(usz)base[(usz)y]]];
                    long common = base[(usz)y]; for (usz i = 0; i < n; i++) blossom[i] = false;
                    x = vv; y = u;
                    while (base[(usz)x] != common) { blossom[(usz)base[(usz)x]] = true; blossom[(usz)base[(usz)match[(usz)x]]] = true; parent[(usz)x] = y; y = match[(usz)x]; x = parent[(usz)match[(usz)x]]; }
                    x = u; y = vv;
                    while (base[(usz)x] != common) { blossom[(usz)base[(usz)x]] = true; blossom[(usz)base[(usz)match[(usz)x]]] = true; parent[(usz)x] = y; y = match[(usz)x]; x = parent[(usz)match[(usz)x]]; }
                    for (usz i = 0; i < n; i++) if (blossom[(usz)base[i]]) { base[i] = common; if (!used[i]) { used[i] = true; queue[tail++] = (long)i; } }
                } else if (parent[uu] == -1) {
                    parent[uu] = vv; if (match[uu] == -1) { endpoint = u; break; }
                    usz next = (usz)match[uu]; used[next] = true; queue[tail++] = (long)next;
                }
            }
        }
        if (endpoint != -1) { long v = endpoint; while (v != -1) { long pv = parent[(usz)v]; long next = match[(usz)pv]; match[(usz)v] = pv; match[(usz)pv] = v; v = next; } if (match[root] != -1) answer++; }
    }
    return answer;
}
