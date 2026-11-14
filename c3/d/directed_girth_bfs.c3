module directed_girth_bfs;

long directed_girth_bfs(long* input, usz length) @export("directed_girth_bfs") {
    if (input == null || length < 2 || length > 131) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 64) return -1;
    usz n = input[0].usz(), m = input[1].usz();
    if (length != 2+2*m) return -1;
    uint[16] outgoing = zeroed;
    for (usz i = 0; i < m; i += 1) {
        long u = input[2+2*i], v = input[3+2*i];
        if (u < 0 || v < 0 || u >= input[0] || v >= input[0]) return -1;
        outgoing[u.usz()] |= (uint)1 << v.usz();
    }
    long best = 17;
    for (usz start = 0; start < n; start += 1) {
        long[16] distance = zeroed;
        usz[16] queue = zeroed;
        for (usz i = 0; i < n; i += 1) distance[i] = -1;
        distance[start] = 0; queue[0] = start;
        usz head = 0, tail = 1;
        while (head < tail) {
            usz u = queue[head++];
            for (usz v = 0; v < n; v += 1) {
                if ((outgoing[u] & ((uint)1 << v)) == 0) continue;
                if (v == start) {
                    if (distance[u]+1 < best) best = distance[u]+1;
                } else if (distance[v] < 0) {
                    distance[v] = distance[u]+1; queue[tail++] = v;
                }
            }
        }
    }
    return best == 17 ? 0 : best;
}
