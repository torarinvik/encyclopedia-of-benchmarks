// Clean-room bounded GBBS Charikar profile; see package LICENSE.txt.
module gbbs_charikar_densest_subgraph;
const usz MAX_N = 16;
const usz MAX_M = 64;
const double INVALID_RESULT = -1e300;

fn double gbbs_charikar_densest_subgraph(long* input, usz length) @export("gbbs_charikar_densest_subgraph") {
    if (input == null || length < 2 || length > 130) return INVALID_RESULT;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M || length != 2 + 2 * (usz)m64) return INVALID_RESULT;
    usz n = (usz)n64, m = (usz)m64;
    uint8[MAX_N * MAX_N] adjacent = zeroed;
    long[MAX_N] degree = zeroed;
    for (usz e = 0; e < m; e += 1) {
        long u64 = input[2 + 2 * e], v64 = input[3 + 2 * e];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID_RESULT;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v] != 0) return INVALID_RESULT;
        adjacent[u * MAX_N + v] = 1; adjacent[v * MAX_N + u] = 1;
        degree[u] += 1; degree[v] += 1;
    }
    bool[MAX_N] alive = zeroed;
    usz[MAX_N] order = zeroed;
    usz[MAX_N] position = zeroed;
    for (usz v = 0; v < n; v += 1) alive[v] = true;
    usz used = 0;
    while (used < n) {
        long level = (long)MAX_M;
        for (usz v = 0; v < n; v += 1) if (alive[v] && degree[v] < level) level = degree[v];
        while (true) {
            usz[MAX_N] shell;
            usz count = 0;
            for (usz v = 0; v < n; v += 1) if (alive[v] && degree[v] == level) { shell[count] = v; count += 1; }
            if (count == 0) break;
            for (usz i = 0; i < count; i += 1) { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
            for (usz v = 0; v < n; v += 1) if (alive[v]) {
                long removed = 0;
                for (usz i = 0; i < count; i += 1) if (adjacent[v * MAX_N + shell[i]] != 0) removed += 1;
                long next = degree[v] - removed;
                degree[v] = next < level ? level : next;
            }
        }
    }
    for (usz i = 0; i < n; i += 1) position[order[i]] = i;
    double best = 0.0;
    for (usz start = 0; start < n; start += 1) {
        usz edges = 0;
        for (usz u = 0; u < n; u += 1) if (position[u] >= start) {
            for (usz v = u + 1; v < n; v += 1) if (position[v] >= start && adjacent[u * MAX_N + v] != 0) edges += 1;
        }
        double score = 2.0 * (double)edges / (double)(n - start);
        if (score > best) best = score;
    }
    return best;
}
