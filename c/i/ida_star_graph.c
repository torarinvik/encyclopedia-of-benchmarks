#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_M = 48, INF = 1000 };

typedef struct {
    int n, goal, threshold, next_threshold;
    int h[MAX_N];
    unsigned adjacency[MAX_N];
} Search;

static int visit(Search *search, int vertex, int distance, unsigned path) {
    int estimate = distance + search->h[vertex];
    if (estimate > search->threshold) {
        if (estimate < search->next_threshold) search->next_threshold = estimate;
        return -1;
    }
    if (vertex == search->goal) return distance;
    for (int next = 0; next < search->n; ++next) {
        unsigned bit = 1u << next;
        if ((search->adjacency[vertex] & bit) && !(path & bit)) {
            int result = visit(search, next, distance + 1, path | bit);
            if (result >= 0) return result;
        }
    }
    return -1;
}

int64_t ida_star_graph(const int64_t *input, size_t length) {
    if (!input || length < 5 || length > 112) return INT64_MIN;
    int64_t nv = input[0], mv = input[1], sv = input[2], gv = input[3];
    if (nv < 1 || nv > MAX_N || mv < 0 || mv > MAX_M ||
        sv < 0 || sv >= nv || gv < 0 || gv >= nv ||
        length != (size_t)(4 + nv + 2 * mv)) return INT64_MIN;
    Search search = {0};
    search.n = (int)nv;
    search.goal = (int)gv;
    for (int i = 0; i < search.n; ++i) {
        if (input[4 + i] < 0 || input[4 + i] >= nv) return INT64_MIN;
        search.h[i] = (int)input[4 + i];
    }
    if (search.h[search.goal] != 0) return INT64_MIN;
    for (int i = 0; i < mv; ++i) {
        int64_t u = input[4 + nv + 2 * i], v = input[5 + nv + 2 * i];
        if (u < 0 || u >= nv || v < 0 || v >= nv || u == v ||
            (search.adjacency[u] & (1u << v)) || search.h[u] > search.h[v] + 1)
            return INT64_MIN;
        search.adjacency[u] |= 1u << v;
    }
    search.threshold = search.h[sv];
    for (;;) {
        search.next_threshold = INF;
        int distance = visit(&search, (int)sv, 0, 1u << sv);
        if (distance >= 0) return distance;
        if (search.next_threshold == INF) return -1;
        search.threshold = search.next_threshold;
    }
}
