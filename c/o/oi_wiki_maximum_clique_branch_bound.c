/* Ordered candidate-intersection search with a suffix-optimum bound. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 24
#define MAX_PARSEABLE_INPUT 26

typedef struct {
    uint64_t adjacency[MAX_VERTICES];
    int suffix_best[MAX_VERTICES];
    int best;
} Clique_Search;

static int bit_count(uint64_t bits)
{
    int count = 0;
    while (bits != 0) {
        bits &= bits - UINT64_C(1);
        ++count;
    }
    return count;
}

static bool search_clique(Clique_Search *search, uint64_t candidates, int chosen)
{
    if (candidates == 0) {
        if (chosen > search->best) {
            search->best = chosen;
            return true;
        }
        return false;
    }

    uint64_t remaining = candidates;
    while (remaining != 0) {
        if (chosen + bit_count(remaining) <= search->best) return false;
        const uint64_t bit = remaining & (~remaining + UINT64_C(1));
        int vertex = 0;
        uint64_t scan = bit;
        while ((scan & UINT64_C(1)) == 0) { scan >>= 1; ++vertex; }
        remaining &= ~bit;
        if (chosen + search->suffix_best[vertex] <= search->best) return false;
        if (search_clique(search, remaining & search->adjacency[vertex], chosen + 1))
            return true;
    }
    return false;
}

int64_t oi_wiki_maximum_clique_branch_bound(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n64 = input[0];
    if (n64 < 0 || n64 > MAX_VERTICES || length != 1 + (size_t)n64) return -1;
    const int n = (int)n64;
    const uint64_t domain = (UINT64_C(1) << n) - UINT64_C(1);
    Clique_Search search = {0};
    for (int vertex = 0; vertex < n; ++vertex) {
        const int64_t row = input[1 + (size_t)vertex];
        if (row < 0 || ((uint64_t)row & ~domain) != 0) return -1;
        search.adjacency[vertex] = (uint64_t)row;
        if (search.adjacency[vertex] & (UINT64_C(1) << vertex)) return -1;
    }
    for (int left = 0; left < n; ++left) {
        for (int right = left + 1; right < n; ++right) {
            const bool forward = (search.adjacency[left] & (UINT64_C(1) << right)) != 0;
            const bool reverse = (search.adjacency[right] & (UINT64_C(1) << left)) != 0;
            if (forward != reverse) return -1;
        }
    }

    for (int root = n - 1; root >= 0; --root) {
        const uint64_t greater = domain & ~((UINT64_C(1) << (root + 1)) - UINT64_C(1));
        (void)search_clique(&search, search.adjacency[root] & greater, 1);
        search.suffix_best[root] = search.best;
    }
    return search.best;
}
