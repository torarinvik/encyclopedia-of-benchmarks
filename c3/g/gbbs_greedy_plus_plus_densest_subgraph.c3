// Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt.
module gbbs_greedy_plus_plus_densest_subgraph;
const usz N = 16;
const usz M = 64;
const double INVALID = -1e300;

fn double gbbs_greedy_plus_plus_densest_subgraph(long* input, usz length) @export("gbbs_greedy_plus_plus_densest_subgraph") {
    if (input == null || length < 2 || length > 132) return INVALID;
    long n64 = input[0], m64 = input[1];
    if (n64 < 10 || n64 > 16 || m64 < 0 || m64 > 64 || length != 2 + 2 * (usz)m64) return INVALID;
    usz n = (usz)n64, m = (usz)m64;
    bool[N * N] adjacent = zeroed;
    long[N] load = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * N + v]) return INVALID;
        adjacent[u * N + v] = true; adjacent[v * N + u] = true;
        load[u] += 1; load[v] += 1;
    }
    double best = 0.0;
    for (usz round = 0; round < 20; round += 1) {
        long[N] degree;
        bool[N] alive = zeroed;
        usz[N] order = zeroed, position = zeroed;
        for (usz vertex = 0; vertex < n; vertex += 1) { degree[vertex] = load[vertex]; alive[vertex] = true; }
        usz used = 0;
        while (used < n) {
            long level = 0x7fffffffffffffff;
            for (usz vertex = 0; vertex < n; vertex += 1) if (alive[vertex] && degree[vertex] < level) level = degree[vertex];
            usz[N] shell;
            usz count = 0;
            for (usz vertex = 0; vertex < n; vertex += 1) if (alive[vertex] && degree[vertex] == level) { shell[count] = vertex; count += 1; }
            for (usz i = 0; i < count; i += 1) { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
            for (usz vertex = 0; vertex < n; vertex += 1) if (alive[vertex]) {
                long removed = 0;
                for (usz i = 0; i < count; i += 1) if (adjacent[vertex * N + shell[i]]) removed += 1;
                long next = degree[vertex] - removed;
                degree[vertex] = next < level ? level : next;
            }
        }
        for (usz i = 0; i < n; i += 1) position[order[i]] = i;
        long[N] density_above = zeroed;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            long later = 0;
            for (usz other = 0; other < n; other += 1) if (adjacent[vertex * N + other] && position[other] > position[vertex]) later += 1;
            density_above[position[vertex]] = 2 * later;
            load[vertex] += later;
        }
        long suffix_sum = 0;
        usz index = n;
        while (index > 0) {
            index -= 1;
            suffix_sum += density_above[index];
            double score = (double)suffix_sum / (double)(n - index);
            if (score > best) best = score;
        }
    }
    return best;
}
