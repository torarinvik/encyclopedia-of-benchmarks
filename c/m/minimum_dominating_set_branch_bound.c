/* Exact minimum dominating set by closed-neighborhood branch and bound. */
#include <stddef.h>
#include <stdint.h>

#define MDS_MAX_N 12
#define MDS_MAX_M 66
#define MDS_MAX_INPUT 135

static int popcount_mask(uint16_t mask)
{
    int count = 0;
    while (mask != 0) {
        mask = (uint16_t)(mask & (uint16_t)(mask - 1));
        ++count;
    }
    return count;
}

static int search_mds(const uint16_t closed[MDS_MAX_N], int n, uint16_t full,
                      uint16_t covered, int chosen, int best)
{
    if (chosen >= best) return best;
    if (covered == full) return chosen;

    const uint16_t uncovered = (uint16_t)(full & (uint16_t)~covered);
    const int uncovered_count = popcount_mask(uncovered);
    int maximum_gain = 0;
    for (int v = 0; v < n; ++v) {
        const int gain = popcount_mask((uint16_t)(closed[v] & uncovered));
        if (gain > maximum_gain) maximum_gain = gain;
    }
    const int lower_bound = (uncovered_count + maximum_gain - 1) / maximum_gain;
    if (chosen + lower_bound >= best) return best;

    int branch = -1;
    int branch_degree = MDS_MAX_N + 1;
    for (int v = 0; v < n; ++v) {
        if ((uncovered & (uint16_t)(1u << v)) != 0) {
            const int degree = popcount_mask(closed[v]);
            if (degree < branch_degree) {
                branch = v;
                branch_degree = degree;
            }
        }
    }

    int candidates[MDS_MAX_N];
    int gains[MDS_MAX_N];
    int count = 0;
    for (int v = 0; v < n; ++v) {
        if ((closed[branch] & (uint16_t)(1u << v)) == 0) continue;
        const int gain = popcount_mask((uint16_t)(closed[v] & uncovered));
        int pos = count;
        while (pos > 0 && (gain > gains[pos - 1] ||
               (gain == gains[pos - 1] && v < candidates[pos - 1]))) {
            gains[pos] = gains[pos - 1];
            candidates[pos] = candidates[pos - 1];
            --pos;
        }
        gains[pos] = gain;
        candidates[pos] = v;
        ++count;
    }
    for (int i = 0; i < count; ++i) {
        const int v = candidates[i];
        best = search_mds(closed, n, full,
                          (uint16_t)(covered | closed[v]), chosen + 1, best);
    }
    return best;
}

int64_t minimum_dominating_set_branch_bound(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > MDS_MAX_INPUT) return -1;
    const int64_t n64 = packed[0], m64 = packed[1];
    if (n64 < 1 || n64 > MDS_MAX_N) return -1;
    const int n = (int)n64;
    const int64_t max_edges = (int64_t)n * (n - 1) / 2;
    if (m64 < 0 || m64 > max_edges || m64 > MDS_MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;

    uint16_t adjacency[MDS_MAX_N] = {0};
    for (int64_t edge = 0; edge < m64; ++edge) {
        const int64_t u64 = packed[2 + 2 * (size_t)edge];
        const int64_t v64 = packed[3 + 2 * (size_t)edge];
        if (u64 < 0 || v64 < 0 || u64 >= n64 || v64 >= n64 || u64 == v64) return -1;
        const int u = (int)u64, v = (int)v64;
        const uint16_t u_bit = (uint16_t)(1u << u);
        const uint16_t v_bit = (uint16_t)(1u << v);
        if ((adjacency[u] & v_bit) != 0) return -1;
        adjacency[u] = (uint16_t)(adjacency[u] | v_bit);
        adjacency[v] = (uint16_t)(adjacency[v] | u_bit);
    }
    uint16_t closed[MDS_MAX_N] = {0};
    for (int v = 0; v < n; ++v) closed[v] = (uint16_t)(adjacency[v] | (uint16_t)(1u << v));
    const uint16_t full = (uint16_t)((1u << n) - 1u);
    uint16_t covered = 0;
    int greedy = 0;
    while (covered != full) {
        int chosen_vertex = 0, best_gain = -1;
        for (int v = 0; v < n; ++v) {
            const int gain = popcount_mask((uint16_t)(closed[v] & (uint16_t)~covered));
            if (gain > best_gain) { best_gain = gain; chosen_vertex = v; }
        }
        covered = (uint16_t)(covered | closed[chosen_vertex]);
        ++greedy;
    }
    return search_mds(closed, n, full, 0, 0, greedy);
}
