/* Clean-room bounded Kanj--Perkovic modified-Yao selection pass. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 42, K = 14, MAX_DARTS = 84,
       MAX_VALID = 312, MAX_PARSEABLE = 313 };

int64_t kanj_perkovic_modified_yao_spanner(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 3 || n64 > MAX_N || m64 < n64 - 1 || m64 > MAX_M ||
        m64 > 3 * n64 - 6 || length != 2 + (size_t)n64 + 7 * (size_t)m64 ||
        length > MAX_VALID) return -1;
    int n = (int)n64, m = (int)m64, darts = 2 * (int)m64;
    int edge_u[MAX_M], edge_v[MAX_M], cone_u[MAX_M], cone_v[MAX_M];
    int64_t weight[MAX_M];
    int adjacent[MAX_N][MAX_N] = {{0}};
    int expected_degree[MAX_N] = {0};
    int source[MAX_DARTS], cone_of[MAX_DARTS];
    for (int e = 0; e < m; ++e) {
        size_t p = 2 + 5 * (size_t)e;
        int64_t u = input[p], v = input[p + 1], w = input[p + 2];
        int64_t cu = input[p + 3], cv = input[p + 4];
        if (u < 0 || u >= v || v >= n || w < 1 || w > INT64_C(1000000000000) ||
            cu < 0 || cu >= K || cv < 0 || cv >= K) return -1;
        if (e > 0 && (u < edge_u[e - 1] || (u == edge_u[e - 1] && v <= edge_v[e - 1]))) return -1;
        edge_u[e] = (int)u; edge_v[e] = (int)v; weight[e] = w;
        cone_u[e] = (int)cu; cone_v[e] = (int)cv;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++expected_degree[u]; ++expected_degree[v];
        source[2 * e] = (int)u; source[2 * e + 1] = (int)v;
        cone_of[2 * e] = (int)cu; cone_of[2 * e + 1] = (int)cv;
    }
    int rotation[MAX_DARTS], position[MAX_DARTS], row_start[MAX_N], degree[MAX_N];
    int bucket_start[MAX_N][K], bucket_end[MAX_N][K];
    unsigned char seen[MAX_DARTS] = {0};
    for (int v = 0; v < n; ++v) for (int c = 0; c < K; ++c)
        bucket_start[v][c] = bucket_end[v][c] = -1;
    size_t cursor = 2 + 5 * (size_t)m, used = 0;
    for (int v = 0; v < n; ++v) {
        int64_t d64 = input[cursor++];
        if (d64 != expected_degree[v] || d64 < 1 || d64 > MAX_DARTS) return -1;
        int d = (int)d64, previous_cone = -1;
        row_start[v] = (int)used; degree[v] = d;
        for (int j = 0; j < d; ++j) {
            int64_t dword = input[cursor++];
            if (dword < 0 || dword >= darts) return -1;
            int dart = (int)dword, c = cone_of[dart];
            if (seen[dart] || source[dart] != v || c < previous_cone) return -1;
            seen[dart] = 1; previous_cone = c;
            rotation[used] = dart; position[dart] = (int)used;
            if (bucket_start[v][c] < 0) bucket_start[v][c] = (int)used;
            bucket_end[v][c] = (int)used + 1;
            ++used;
        }
    }
    if (cursor != length || used != (size_t)darts) return -1;
    for (int d = 0; d < darts; ++d) if (!seen[d]) return -1;

    int visited_v[MAX_N] = {0}, queue[MAX_N], head = 0, tail = 0;
    queue[tail++] = 0; visited_v[0] = 1;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < n; ++v) if (adjacent[u][v] && !visited_v[v]) {
            visited_v[v] = 1; queue[tail++] = v;
        }
    }
    if (tail != n) return -1;
    int face_next[MAX_DARTS], face_seen[MAX_DARTS] = {0}, faces = 0;
    for (int d = 0; d < darts; ++d) {
        int twin = d ^ 1, destination = source[twin];
        int local = position[twin] - row_start[destination];
        int before = (local + degree[destination] - 1) % degree[destination];
        face_next[d] = rotation[row_start[destination] + before];
    }
    for (int d = 0; d < darts; ++d) if (!face_seen[d]) {
        ++faces; int x = d;
        while (!face_seen[x]) { face_seen[x] = 1; x = face_next[x]; }
        if (x != d) return -1;
    }
    if (n - m + faces != 2) return -1;

    unsigned char selected[MAX_DARTS] = {0};
    for (int v = 0; v < n; ++v) for (int c = 0; c < K; ++c) {
        int lo = bucket_start[v][c], hi = bucket_end[v][c];
        if (lo < 0) continue;
        int best = -1;
        for (int p = lo; p < hi; ++p) {
            int d = rotation[p], e = d / 2;
            if (best < 0 || weight[e] < weight[best / 2] ||
                (weight[e] == weight[best / 2] && e < best / 2)) best = d;
        }
        selected[best] = 1;
    }
    for (int v = 0; v < n; ++v) {
        int occupied = 0;
        for (int c = 0; c < K; ++c) occupied += bucket_start[v][c] >= 0;
        if (!occupied) continue;
        for (int start = 0; start < K; ++start) {
            if (bucket_start[v][start] >= 0 || bucket_start[v][(start + K - 1) % K] < 0) continue;
            int len = 0;
            while (len < K && bucket_start[v][(start + len) % K] < 0) ++len;
            if (len == 1) {
                int cw_c = (start + K - 1) % K, ccw_c = (start + 1) % K;
                int cw = rotation[bucket_end[v][cw_c] - 1];
                int ccw = rotation[bucket_start[v][ccw_c]];
                if (selected[cw]) selected[ccw] = 1;
                else if (selected[ccw]) selected[cw] = 1;
                else {
                    int ecw = cw / 2, eccw = ccw / 2;
                    if (weight[ecw] < weight[eccw] ||
                        (weight[ecw] == weight[eccw] && ecw < eccw)) selected[cw] = 1;
                    else selected[ccw] = 1;
                }
            } else {
                int need_cw = len / 2, need_ccw = (len + 1) / 2;
                for (int step = 1; step <= K && need_cw > 0; ++step) {
                    int c = (start - step + K) % K;
                    for (int p = bucket_end[v][c] - 1; p >= bucket_start[v][c] && need_cw > 0; --p)
                        if (!selected[rotation[p]]) { selected[rotation[p]] = 1; --need_cw; }
                }
                for (int step = len; step < len + K && need_ccw > 0; ++step) {
                    int c = (start + step) % K;
                    for (int p = bucket_start[v][c]; p >= 0 && p < bucket_end[v][c] && need_ccw > 0; ++p)
                        if (!selected[rotation[p]]) { selected[rotation[p]] = 1; --need_ccw; }
                }
            }
        }
    }
    uint64_t mask = 0;
    for (int e = 0; e < m; ++e) if (selected[2 * e] && selected[2 * e + 1]) mask |= UINT64_C(1) << e;
    return (int64_t)mask;
}
