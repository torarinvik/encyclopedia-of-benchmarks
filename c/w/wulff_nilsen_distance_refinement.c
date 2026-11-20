#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 28, MAX_PARSEABLE = 93, K = 4, MAX_REDUCTIONS = 16 };
static const int64_t SCALE = INT64_C(86093442);
static const int64_t INF = INT64_C(1) << 60;

static int wn_bunch_has(const uint8_t bunch[MAX_N][MAX_N], int center, int vertex) {
    return bunch[center][vertex] != 0;
}

static int wn_even_index(int vertex, int64_t threshold,
                         const int nearest[K][MAX_N],
                         const int64_t distance[MAX_N][MAX_N]) {
    return distance[vertex][nearest[2][vertex]] <= threshold ? 2 : 0;
}

static int wn_refine_further(int source, int target, int even_source,
                             const int nearest[K][MAX_N],
                             const uint8_t bunch[MAX_N][MAX_N],
                             const int64_t distance[MAX_N][MAX_N]) {
    if (even_source < 2) return 0;
    const int j = 0;
    if (wn_bunch_has(bunch, target, nearest[j][source]) ||
        wn_bunch_has(bunch, source, nearest[j + 1][target])) return 1;
    return wn_bunch_has(bunch, target, nearest[even_source][source]) ||
           wn_bunch_has(bunch, source, nearest[even_source + 1][target]);
}

int64_t wulff_nilsen_distance_refinement(const int64_t *input, size_t length) {
    if (input == NULL || length < 8U || length > MAX_PARSEABLE) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M) return -1;
    const int n = (int)n64, m = (int)m64;
    if (length != 8U + 3U * (size_t)m) return -1;

    const int64_t full = (INT64_C(1) << n) - 1;
    int64_t masks[3];
    for (int i = 0; i < 3; ++i) {
        masks[i] = input[2 + i];
        if (masks[i] <= 0 || (masks[i] & ~full) != 0) return -1;
    }
    if ((masks[1] & ~masks[0]) != 0 || (masks[2] & ~masks[1]) != 0) return -1;

    int64_t distance[MAX_N][MAX_N];
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v)
            distance[u][v] = u == v ? 0 : INF;
    int previous_u = -1, previous_v = -1;
    for (int e = 0; e < m; ++e) {
        const size_t at = 5U + 3U * (size_t)e;
        const int64_t u64 = input[at], v64 = input[at + 1], weight = input[at + 2];
        if (u64 < 0 || u64 >= n || v64 <= u64 || v64 >= n ||
            weight < SCALE || weight > SCALE * 100 || weight % SCALE != 0) return -1;
        const int u = (int)u64, v = (int)v64;
        if (u < previous_u || (u == previous_u && v <= previous_v)) return -1;
        previous_u = u;
        previous_v = v;
        distance[u][v] = weight;
        distance[v][u] = weight;
    }

    const size_t query_at = 5U + 3U * (size_t)m;
    const int64_t source64 = input[query_at], target64 = input[query_at + 1];
    const int64_t estimate = input[query_at + 2];
    if (source64 < 0 || source64 >= n || target64 < 0 || target64 >= n ||
        source64 == target64 || estimate <= 0 || estimate % SCALE != 0) return -1;
    const int source = (int)source64, target = (int)target64;

    for (int middle = 0; middle < n; ++middle)
        for (int u = 0; u < n; ++u) {
            if (distance[u][middle] == INF) continue;
            for (int v = 0; v < n; ++v) {
                const int64_t candidate = distance[u][middle] + distance[middle][v];
                if (candidate < distance[u][v]) distance[u][v] = candidate;
            }
        }
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v)
            if (distance[u][v] == INF) return -1;
    if (estimate < distance[source][target] ||
        estimate > INT64_C(768) * distance[source][target]) return -1;

    int nearest[K][MAX_N] = {{0}};
    for (int x = 0; x < n; ++x) {
        nearest[0][x] = x;
        for (int level = 1; level < K; ++level) {
            int chosen = -1;
            for (int y = 0; y < n; ++y) {
                if (((masks[level - 1] >> y) & 1) == 0) continue;
                if (chosen < 0 || distance[x][y] < distance[x][chosen] ||
                    (distance[x][y] == distance[x][chosen] && y < chosen)) chosen = y;
            }
            nearest[level][x] = chosen;
        }
    }

    const int64_t layers[5] = {full, masks[0], masks[1], masks[2], 0};
    uint8_t bunch[MAX_N][MAX_N] = {{0}};
    for (int center = 0; center < n; ++center)
        for (int level = 0; level < K; ++level) {
            int64_t boundary = INF;
            for (int y = 0; y < n; ++y)
                if ((layers[level + 1] >> y) & 1)
                    if (distance[center][y] < boundary) boundary = distance[center][y];
            for (int y = 0; y < n; ++y)
                if (((layers[level] >> y) & 1) && !((layers[level + 1] >> y) & 1) &&
                    distance[center][y] < boundary) bunch[center][y] = 1;
        }

    int64_t value = estimate;
    int even_source = wn_even_index(source, value, nearest, distance);
    if (!wn_refine_further(source, target, even_source, nearest, bunch, distance)) return value;
    int iteration = 0;
    while (wn_refine_further(source, target, even_source, nearest, bunch, distance) &&
           iteration <= 15) {
        value = (2 * value) / 3;
        even_source = wn_even_index(source, value, nearest, distance);
        ++iteration;
    }
    const int upper_even = wn_even_index(source, (3 * value) / 2, nearest, distance);
    if (upper_even < 2) return -1;
    const int j = 0;
    int pivot = nearest[j][source];
    if (wn_bunch_has(bunch, target, pivot)) return distance[source][pivot] + distance[target][pivot];
    pivot = nearest[j + 1][target];
    if (wn_bunch_has(bunch, source, pivot)) return distance[source][pivot] + distance[target][pivot];
    pivot = nearest[upper_even][source];
    if (wn_bunch_has(bunch, target, pivot)) return distance[source][pivot] + distance[target][pivot];
    pivot = nearest[upper_even + 1][target];
    return distance[source][pivot] + distance[target][pivot];
}
