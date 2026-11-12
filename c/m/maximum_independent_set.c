/* Exact MIS by maximum-degree branching and a greedy clique-cover bound. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 22
#define MAX_INPUT 465

typedef struct {
    uint64_t adjacency[MAX_N];
    int best;
} MisSearch;

static int popcount64(uint64_t bits)
{
    int count = 0;
    while (bits != 0) {
        bits &= bits - 1;
        ++count;
    }
    return count;
}

static int first_vertex(uint64_t bits)
{
    int vertex = 0;
    while ((bits & UINT64_C(1)) == 0) {
        bits >>= 1;
        ++vertex;
    }
    return vertex;
}

static int clique_cover_bound(const MisSearch *search, uint64_t remaining)
{
    int cliques = 0;
    while (remaining != 0) {
        ++cliques;
        uint64_t candidates = remaining;
        while (candidates != 0) {
            const uint64_t bit = candidates & (~candidates + UINT64_C(1));
            const int vertex = first_vertex(bit);
            remaining &= ~bit;
            candidates &= ~bit;
            candidates &= search->adjacency[vertex];
        }
    }
    return cliques;
}

static void search_mis(MisSearch *search, uint64_t remaining, int chosen)
{
    if (remaining == 0) {
        if (chosen > search->best) search->best = chosen;
        return;
    }
    if (chosen + popcount64(remaining) <= search->best) return;
    if (chosen + clique_cover_bound(search, remaining) <= search->best) return;

    int branch = -1, branch_degree = -1;
    uint64_t vertices = remaining;
    while (vertices != 0) {
        const uint64_t bit = vertices & (~vertices + UINT64_C(1));
        const int vertex = first_vertex(bit);
        const int degree = popcount64(search->adjacency[vertex] & remaining);
        if (degree > branch_degree) {
            branch = vertex;
            branch_degree = degree;
        }
        vertices &= ~bit;
    }
    const uint64_t bit = UINT64_C(1) << branch;
    search_mis(search, remaining & ~bit & ~search->adjacency[branch], chosen + 1);
    search_mis(search, remaining & ~bit, chosen);
}

int64_t maximum_independent_set(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = packed[0], m64 = packed[1];
    if (n64 < 0 || n64 > MAX_N) return -1;
    const int n = (int)n64;
    const int64_t max_edges = (int64_t)n * (n - 1) / 2;
    if (m64 < 0 || m64 > max_edges || length != 2 + 2 * (size_t)m64) return -1;

    MisSearch search = {0};
    for (int64_t edge = 0; edge < m64; ++edge) {
        const int64_t u64 = packed[2 + 2 * (size_t)edge];
        const int64_t v64 = packed[3 + 2 * (size_t)edge];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64) return -1;
        const int u = (int)u64, v = (int)v64;
        const uint64_t v_bit = UINT64_C(1) << v;
        if (search.adjacency[u] & v_bit) return -1;
        search.adjacency[u] |= v_bit;
        search.adjacency[v] |= UINT64_C(1) << u;
    }
    search_mis(&search, (UINT64_C(1) << n) - UINT64_C(1), 0);
    return search.best;
}
