module gapbs_betweenness_centrality;

const usz MAX_N = 8;

// Clean-room bounded Brandes profile; see package LICENSE.txt.
fn long gapbs_betweenness_centrality(long* input, usz length) @export("gapbs_betweenness_centrality") {
    if (input == null || length < 12 || length > 74) return -1;
    long n64 = input[0], k64 = input[1];
    if (n64 < 3 || n64 > 8 || k64 < 1 || k64 > n64) return -1;
    usz n = (usz)n64, k = (usz)k64;
    if (length != 2 + k + n * n) return -1;
    long[8] sources;
    for (usz i = 0; i < k; i++) {
        long source = input[2 + i];
        if (source < 0 || source >= n64) return -1;
        for (usz j = 0; j < i; j++) if (sources[j] == source) return -1;
        sources[i] = source;
    }
    long[64] adjacency;
    for (usz u = 0; u < n; u++) {
        for (usz v = 0; v < n; v++) {
            long edge = input[2 + k + u * n + v];
            if ((edge != 0 && edge != 1) || (u == v && edge != 0)) return -1;
            adjacency[u * 8 + v] = edge;
        }
    }
    for (usz u = 0; u < n; u++)
        for (usz v = u + 1; v < n; v++)
            if (adjacency[u * 8 + v] != adjacency[v * 8 + u]) return -1;

    float[8] scores = zeroed;
    for (usz si = 0; si < k; si++) {
        long[8] depth;
        usz[8] queue;
        double[8] paths = zeroed;
        float[8] delta = zeroed;
        for (usz v = 0; v < n; v++) depth[v] = -1;
        usz source = (usz)sources[si];
        depth[source] = 0; paths[source] = 1.0;
        usz head = 0, tail = 0;
        queue[tail] = source; tail++;
        while (head < tail) {
            usz u = queue[head]; head++;
            for (usz v = 0; v < n; v++) if (adjacency[u * 8 + v] != 0) {
                if (depth[v] == -1) { depth[v] = depth[u] + 1; queue[tail] = v; tail++; }
                if (depth[v] == depth[u] + 1) paths[v] += paths[u];
            }
        }
        long max_depth = 0;
        for (usz v = 0; v < n; v++) if (depth[v] > max_depth) max_depth = depth[v];
        long d = max_depth;
        while (d >= 0) {
            for (usz u = 0; u < n; u++) if (depth[u] == d) {
                float delta_u = 0.0;
                for (usz v = 0; v < n; v++) if (adjacency[u * 8 + v] != 0 && depth[v] == d + 1) {
                    float one_plus = 1.0 + delta[v];
                    double contribution = (paths[u] / paths[v]) * (double)one_plus;
                    delta_u = (float)((double)delta_u + contribution);
                }
                delta[u] = delta_u;
                scores[u] = (float)((double)scores[u] + (double)delta_u);
            }
            d--;
        }
    }
    float biggest = 0.0;
    for (usz v = 0; v < n; v++) if (scores[v] > biggest) biggest = scores[v];
    if (!(biggest > 0.0)) return -1;
    long checksum = 0;
    for (usz v = 0; v < n; v++) {
        float normalized = scores[v] / biggest;
        long qscore = (long)((double)normalized * 1000.0 + 0.5);
        checksum += (long)(v + 1) * qscore;
    }
    return checksum;
}
