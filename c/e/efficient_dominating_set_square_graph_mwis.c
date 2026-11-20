#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 12, MAX_VALID_INPUT = 134, MAX_PARSEABLE_INPUT = 135 };

typedef struct {
    uint64_t square[MAX_VERTICES];
    int weight[MAX_VERTICES];
    int best;
} WeightedSearch;

static int popcount64(uint64_t bits) {
    int count = 0;
    while (bits != 0) { bits &= bits - 1; ++count; }
    return count;
}

static void search_weighted_mis(WeightedSearch *search, uint64_t remaining, int current) {
    int upper_bound = current;
    uint64_t scan = remaining;
    while (scan != 0) {
        const uint64_t bit = scan & (~scan + UINT64_C(1));
        int vertex = 0;
        uint64_t probe = bit;
        while ((probe & UINT64_C(1)) == 0) { probe >>= 1; ++vertex; }
        upper_bound += search->weight[vertex];
        scan &= ~bit;
    }
    if (upper_bound <= search->best) return;
    if (remaining == 0) { search->best = current; return; }

    int branch = -1, branch_degree = -1;
    for (int vertex = 0; vertex < MAX_VERTICES; ++vertex) {
        const uint64_t bit = UINT64_C(1) << vertex;
        if ((remaining & bit) == 0) continue;
        const int degree = popcount64(search->square[vertex] & remaining);
        if (degree > branch_degree) { branch = vertex; branch_degree = degree; }
    }
    const uint64_t bit = UINT64_C(1) << branch;
    search_weighted_mis(search, remaining & ~bit & ~search->square[branch],
                        current + search->weight[branch]);
    search_weighted_mis(search, remaining & ~bit, current);
}

int64_t efficient_dominating_set_square_graph_mwis(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_VERTICES) return -1;
    const int64_t maximum_edges = n64 * (n64 - 1) / 2;
    if (m64 < 0 || m64 > maximum_edges || length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64;
    uint64_t adjacency[MAX_VERTICES] = {0};
    for (int64_t edge = 0; edge < m64; ++edge) {
        const int64_t u64 = input[2 + 2 * (size_t)edge];
        const int64_t v64 = input[3 + 2 * (size_t)edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const int u = (int)u64, v = (int)v64;
        const uint64_t v_bit = UINT64_C(1) << v;
        if (adjacency[u] & v_bit) return -1;
        adjacency[u] |= v_bit;
        adjacency[v] |= UINT64_C(1) << u;
    }

    WeightedSearch search = {0};
    for (int vertex = 0; vertex < n; ++vertex) {
        search.square[vertex] = adjacency[vertex];
        uint64_t neighbors = adjacency[vertex];
        while (neighbors != 0) {
            const uint64_t bit = neighbors & (~neighbors + UINT64_C(1));
            int neighbor = 0;
            uint64_t probe = bit;
            while ((probe & UINT64_C(1)) == 0) { probe >>= 1; ++neighbor; }
            search.square[vertex] |= adjacency[neighbor];
            neighbors &= ~bit;
        }
        search.square[vertex] &= ~(UINT64_C(1) << vertex);
        search.weight[vertex] = popcount64(adjacency[vertex]) + 1;
    }
    const uint64_t all_vertices = (UINT64_C(1) << n) - UINT64_C(1);
    search_weighted_mis(&search, all_vertices, 0);
    return search.best == n ? 1 : 0;
}
