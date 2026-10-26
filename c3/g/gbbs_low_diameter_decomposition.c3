// Clean-room bounded GBBS MPX low-diameter decomposition profile.
module gbbs_low_diameter_decomposition;
const usz N = 12;
const usz M = 24;
const usz INPUT = 2 + 2 * M;
const usz ROUNDS = 13;
const usz[ROUNDS] BATCH = {1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11};

long gbbs_low_diameter_decomposition(long* input, usz length, char* output, usz capacity)
        @export("gbbs_low_diameter_decomposition") {
    if (input == null || length < 2 || length > INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 12 || m64 < 0 || m64 > 24 ||
        length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    bool[N * N] adjacent = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * N + v]) return -1;
        adjacent[u * N + v] = true;
        adjacent[v * N + u] = true;
    }
    if (output == null || capacity < n) return -2;

    long[N] label = zeroed;
    usz[N] frontier = zeroed;
    for (usz v = 0; v < n; v += 1) label[v] = -1;
    usz frontier_count = 0, cursor = 0, assigned = 0, round = 0;
    while (assigned < n) {
        usz end = cursor + BATCH[round];
        if (end > n) end = n;
        for (usz candidate = cursor; candidate < end; candidate += 1) {
            if (label[candidate] < 0) {
                label[candidate] = (long)candidate;
                frontier[frontier_count] = candidate;
                frontier_count += 1;
                assigned += 1;
            }
        }
        cursor = end;
        if (assigned == n) break;

        long[N] reached = zeroed;
        for (usz v = 0; v < n; v += 1) reached[v] = -1;
        for (usz i = 0; i < frontier_count; i += 1) {
            usz vertex = frontier[i];
            for (usz neighbor = 0; neighbor < n; neighbor += 1) {
                if (adjacent[vertex * N + neighbor] && label[neighbor] < 0 &&
                    (reached[neighbor] < 0 || label[vertex] < reached[neighbor]))
                    reached[neighbor] = label[vertex];
            }
        }
        frontier_count = 0;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if (reached[vertex] >= 0) {
                label[vertex] = reached[vertex];
                frontier[frontier_count] = vertex;
                frontier_count += 1;
                assigned += 1;
            }
        }
        round += 1;
    }
    for (usz vertex = 0; vertex < n; vertex += 1) output[vertex] = (char)label[vertex];
    return (long)n;
}
