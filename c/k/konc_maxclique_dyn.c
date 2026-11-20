/* Clean-room bounded MaxCliqueDyn-style colored branch and bound. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 24
#define MAX_PARSEABLE_INPUT 26

typedef struct { int vertex; int bound; } Candidate;
typedef struct {
    uint64_t adjacency[MAX_VERTICES];
    int chosen[MAX_VERTICES];
    int chosen_count;
    int best;
    int steps[MAX_VERTICES + 2];
    int prior_child_steps[MAX_VERTICES + 2];
    int total_color_calls;
} Search;

static void degree_order(Search *search, const int *vertices, int count,
                         Candidate *ordered)
{
    int ids[MAX_VERTICES];
    int degrees[MAX_VERTICES];
    int maximum_degree = 0;
    for (int i = 0; i < count; ++i) {
        ids[i] = vertices[i];
        int degree = 0;
        for (int j = 0; j < count; ++j)
            degree += (int)((search->adjacency[ids[i]] >> vertices[j]) & UINT64_C(1));
        degrees[i] = degree;
        if (degree > maximum_degree) maximum_degree = degree;
    }
    for (int i = 1; i < count; ++i) {
        const int id = ids[i];
        const int degree = degrees[i];
        int j = i;
        while (j > 0 && (degrees[j - 1] < degree
                || (degrees[j - 1] == degree && ids[j - 1] > id))) {
            ids[j] = ids[j - 1];
            degrees[j] = degrees[j - 1];
            --j;
        }
        ids[j] = id;
        degrees[j] = degree;
    }
    for (int i = 0; i < count; ++i) {
        ordered[i].vertex = ids[i];
        ordered[i].bound = (i < maximum_degree ? i : maximum_degree) + 1;
    }
}

static void expand(Search *search, const Candidate *candidates, int count, int level)
{
    search->steps[level] += search->steps[level - 1] - search->prior_child_steps[level];
    search->prior_child_steps[level] = search->steps[level - 1];
    while (count > 0) {
        if (search->chosen_count + candidates[count - 1].bound <= search->best) return;
        const int vertex = candidates[count - 1].vertex;
        search->chosen[search->chosen_count++] = vertex;

        int neighbors[MAX_VERTICES];
        int neighbor_count = 0;
        for (int i = 0; i + 1 < count; ++i) {
            const int other = candidates[i].vertex;
            if (search->adjacency[vertex] & (UINT64_C(1) << other))
                neighbors[neighbor_count++] = other;
        }
        if (neighbor_count > 0) {
            const int prior_steps = search->steps[level]++;
            ++search->total_color_calls;
            if ((int64_t)prior_steps * 1000 < (int64_t)search->total_color_calls * 25) {
                Candidate reordered[MAX_VERTICES];
                degree_order(search, neighbors, neighbor_count, reordered);
                for (int i = 0; i < neighbor_count; ++i)
                    neighbors[i] = reordered[i].vertex;
            }

            uint64_t class_masks[MAX_VERTICES] = {0};
            int colors[MAX_VERTICES];
            int class_count = 0;
            for (int i = 0; i < neighbor_count; ++i) {
                int color = 0;
                while (color < class_count
                       && (class_masks[color] & search->adjacency[neighbors[i]]) != 0)
                    ++color;
                if (color == class_count) ++class_count;
                colors[i] = color + 1;
                class_masks[color] |= UINT64_C(1) << neighbors[i];
            }

            const int minimum_color = search->best - search->chosen_count + 1 > 1
                ? search->best - search->chosen_count + 1 : 1;
            Candidate child[MAX_VERTICES];
            int child_count = 0;
            for (int color = minimum_color; color <= class_count; ++color) {
                for (int i = 0; i < neighbor_count; ++i) {
                    if (colors[i] == color) {
                        child[child_count].vertex = neighbors[i];
                        child[child_count].bound = color;
                        ++child_count;
                    }
                }
            }
            expand(search, child, child_count, level + 1);
        } else if (search->chosen_count > search->best) {
            search->best = search->chosen_count;
        }

        --search->chosen_count;
        --count;
    }
}

int64_t konc_maxclique_dyn(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n64 = input[0];
    if (n64 < 0 || n64 > MAX_VERTICES || length != 1 + (size_t)n64) return -1;
    const int n = (int)n64;
    const uint64_t domain = (UINT64_C(1) << n) - UINT64_C(1);
    Search search = {0};
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
    if (n == 0) return 0;
    int vertices[MAX_VERTICES];
    Candidate roots[MAX_VERTICES];
    for (int i = 0; i < n; ++i) vertices[i] = i;
    degree_order(&search, vertices, n, roots);
    expand(&search, roots, n, 1);
    return search.best;
}
