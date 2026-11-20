#include <stddef.h>
#include <stdint.h>

enum { K = 16, MAX_N = 8, MAX_M = 28, MAX_Q = 32, MAX_INPUT = 167,
       MAX_NODES = 31, LOG_K = 4 };
#define INF INT64_C(0x3fffffffffffffff)

typedef struct {
    int lo, hi, mid, j, left, right;
} IntervalNode;

static void put_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8u * b));
}

static int build_node(IntervalNode trees[MAX_N][MAX_NODES], int counts[MAX_N],
                      int64_t distance[MAX_N][MAX_N],
                      int nearest[K][MAX_N], int source, int lo, int hi) {
    int index = counts[source]++;
    IntervalNode *node = &trees[source][index];
    node->lo = lo; node->hi = hi;
    node->mid = -1; node->j = -1; node->left = -1; node->right = -1;
    if (hi - lo <= LOG_K) return index;

    int mid = -1, best_mid_gap = 0x7fffffff;
    for (int candidate = lo + 2; candidate <= hi - 2; candidate += 2) {
        int gap = 2 * candidate - lo - hi;
        if (gap < 0) gap = -gap;
        if (gap < best_mid_gap) { best_mid_gap = gap; mid = candidate; }
    }
    if (mid < 0 || index >= MAX_NODES) return -1;

    int best_j = lo;
    int64_t best_delta = distance[source][nearest[lo + 2][source]] -
                         distance[source][nearest[lo][source]];
    for (int level = lo + 2; level <= mid - 2; level += 2) {
        int64_t delta = distance[source][nearest[level + 2][source]] -
                        distance[source][nearest[level][source]];
        if (delta > best_delta) { best_delta = delta; best_j = level; }
    }
    node->mid = mid; node->j = best_j;
    int left = build_node(trees, counts, distance, nearest, source, lo, best_j);
    int right = build_node(trees, counts, distance, nearest, source, mid, hi);
    if (left < 0 || right < 0) return -1;
    node->left = left; node->right = right;
    return index;
}

static int dist_k(int64_t distance[MAX_N][MAX_N], int nearest[K][MAX_N],
                  uint8_t bunch[MAX_N][MAX_N], int n, int u, int v, int start,
                  int64_t *estimate, int *probes) {
    int level = start;
    for (;;) {
        int pivot = nearest[level][u];
        ++*probes;
        if (bunch[v][pivot]) {
            *estimate = distance[u][pivot] + distance[v][pivot];
            return 1;
        }
        if (level + 1 >= K) return 0;
        int temporary = u; u = v; v = temporary;
        ++level;
        if (u < 0 || u >= n) return 0;
    }
}

int64_t wulff_nilsen_logarithmic_distance_query(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 18 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M) return -1;
    int n = (int)n64, m = (int)m64;

    uint64_t masks[K] = {0};
    uint64_t valid_bits = ((uint64_t)1 << (unsigned)n) - 1u;
    for (int level = 1; level < K; ++level) {
        int64_t value = input[1 + level];
        if (value <= 0 || ((uint64_t)value & ~valid_bits) != 0) return -1;
        masks[level] = (uint64_t)value;
        if (level > 1 && (masks[level] & ~masks[level - 1]) != 0) return -1;
    }

    size_t q_at = 17u + 3u * (size_t)m;
    if (q_at >= length) return -1;
    int64_t q64 = input[q_at];
    if (q64 < 0 || q64 > MAX_Q || length != q_at + 1u + 2u * (size_t)q64) return -1;
    int q = (int)q64;

    int64_t distance[MAX_N][MAX_N];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) distance[i][j] = i == j ? 0 : INF;
    int previous_u = -1, previous_v = -1;
    for (int e = 0; e < m; ++e) {
        int64_t u64 = input[17 + 3 * e], v64 = input[18 + 3 * e];
        int64_t weight = input[19 + 3 * e];
        if (u64 < 0 || v64 <= u64 || v64 >= n || weight < 1 || weight > 1000) return -1;
        int u = (int)u64, v = (int)v64;
        if (u < previous_u || (u == previous_u && v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        distance[u][v] = distance[v][u] = weight;
    }
    for (int k = 0; k < n; ++k)
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j)
                if (distance[i][k] != INF && distance[k][j] != INF &&
                    distance[i][k] + distance[k][j] < distance[i][j])
                    distance[i][j] = distance[i][k] + distance[k][j];
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            if (distance[i][j] == INF) return -1;

    int nearest[K][MAX_N] = {{0}};
    for (int vertex = 0; vertex < n; ++vertex) nearest[0][vertex] = vertex;
    for (int level = 1; level < K; ++level) {
        for (int vertex = 0; vertex < n; ++vertex) {
            int best = -1;
            for (int candidate = 0; candidate < n; ++candidate) {
                if (((masks[level] >> (unsigned)candidate) & 1u) == 0) continue;
                if (best < 0 || distance[vertex][candidate] < distance[vertex][best] ||
                    (distance[vertex][candidate] == distance[vertex][best] && candidate < best))
                    best = candidate;
            }
            if (best < 0) return -1;
            nearest[level][vertex] = best;
        }
    }

    uint8_t bunch[MAX_N][MAX_N] = {{0}};
    for (int center = 0; center < n; ++center) {
        for (int level = 0; level < K; ++level) {
            uint64_t current = level == 0 ? valid_bits : masks[level];
            uint64_t following = level + 1 == K ? 0 : masks[level + 1];
            int64_t next_distance = INF;
            for (int candidate = 0; candidate < n; ++candidate)
                if (((following >> (unsigned)candidate) & 1u) &&
                    distance[center][candidate] < next_distance)
                    next_distance = distance[center][candidate];
            for (int candidate = 0; candidate < n; ++candidate) {
                int in_current = (int)((current >> (unsigned)candidate) & 1u);
                int in_next = (int)((following >> (unsigned)candidate) & 1u);
                if (in_current && !in_next && distance[center][candidate] < next_distance)
                    bunch[center][candidate] = 1;
            }
        }
    }

    IntervalNode trees[MAX_N][MAX_NODES];
    int counts[MAX_N] = {0};
    for (int source = 0; source < n; ++source)
        if (build_node(trees, counts, distance, nearest, source, 0, K - 1) < 0) return -1;

    int64_t staged[1 + 2 * MAX_Q] = {0};
    staged[0] = q;
    for (int qi = 0; qi < q; ++qi) {
        int64_t source64 = input[q_at + 1u + 2u * (size_t)qi];
        int64_t target64 = input[q_at + 2u + 2u * (size_t)qi];
        if (source64 < 0 || source64 >= n || target64 < 0 || target64 >= n) return -1;
        int source = (int)source64, target = (int)target64, node_index = 0, probes = 0;
        if (source == target) {
            staged[1 + 2 * qi] = 0;
            staged[2 + 2 * qi] = 0;
            continue;
        }
        while (trees[source][node_index].hi - trees[source][node_index].lo > LOG_K) {
            IntervalNode *node = &trees[source][node_index];
            int first = bunch[target][nearest[node->j][source]];
            int second = bunch[source][nearest[node->j + 1][target]];
            probes += 2;
            node_index = (!first && !second) ? node->right : node->left;
        }
        int64_t estimate = 0;
        if (!dist_k(distance, nearest, bunch, n, source, target,
                    trees[source][node_index].lo, &estimate, &probes)) return -1;
        staged[1 + 2 * qi] = estimate;
        staged[2 + 2 * qi] = probes;
    }

    size_t bytes = 8u * (size_t)(1 + 2 * q);
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < (size_t)(1 + 2 * q); ++i) put_i64_le(output, 8u * i, staged[i]);
    return (int64_t)bytes;
}
