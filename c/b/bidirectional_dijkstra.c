/* Shortest distance in a bounded directed graph using two Dijkstra frontiers. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 256
#define MAX_WEIGHT 1000000

int64_t bidirectional_dijkstra(const int64_t *input, size_t length) {
    if (input == NULL || length < 4) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    const int64_t source_value = input[2], target_value = input[3];
    if (n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (source_value < 0 || source_value >= n_value || target_value < 0 || target_value >= n_value)
        return -1;
    if (length != 4 + 3 * m) return -1;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t from = input[4 + 3 * edge];
        const int64_t to = input[5 + 3 * edge];
        const int64_t weight = input[6 + 3 * edge];
        if (from < 0 || from >= n_value || to < 0 || to >= n_value || weight < 0 || weight > MAX_WEIGHT)
            return -1;
    }
    const size_t source = (size_t)source_value, target = (size_t)target_value;
    if (source == target) return 0;

    const int64_t inf = INT64_MAX;
    int64_t forward[MAX_VERTICES], backward[MAX_VERTICES];
    uint8_t settled_forward[MAX_VERTICES] = {0}, settled_backward[MAX_VERTICES] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        forward[vertex] = inf;
        backward[vertex] = inf;
    }
    forward[source] = 0;
    backward[target] = 0;
    int64_t best = inf;

    for (size_t step = 0; step < 2 * n; ++step) {
        size_t next_forward = n, next_backward = n;
        int64_t min_forward = inf, min_backward = inf;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (!settled_forward[vertex] && forward[vertex] < min_forward) {
                min_forward = forward[vertex];
                next_forward = vertex;
            }
            if (!settled_backward[vertex] && backward[vertex] < min_backward) {
                min_backward = backward[vertex];
                next_backward = vertex;
            }
        }
        if (next_forward == n || next_backward == n) break;
        if (best != inf && min_forward + min_backward >= best) break;

        if (min_forward <= min_backward) {
            const size_t current = next_forward;
            settled_forward[current] = 1;
            if (backward[current] != inf && forward[current] + backward[current] < best)
                best = forward[current] + backward[current];
            for (size_t edge = 0; edge < m; ++edge) {
                const size_t from = (size_t)input[4 + 3 * edge];
                if (from != current) continue;
                const size_t to = (size_t)input[5 + 3 * edge];
                const int64_t candidate = forward[current] + input[6 + 3 * edge];
                if (!settled_forward[to] && candidate < forward[to]) forward[to] = candidate;
                if (backward[to] != inf && candidate + backward[to] < best)
                    best = candidate + backward[to];
            }
        } else {
            const size_t current = next_backward;
            settled_backward[current] = 1;
            if (forward[current] != inf && forward[current] + backward[current] < best)
                best = forward[current] + backward[current];
            for (size_t edge = 0; edge < m; ++edge) {
                const size_t to = (size_t)input[5 + 3 * edge];
                if (to != current) continue;
                const size_t from = (size_t)input[4 + 3 * edge];
                const int64_t candidate = backward[current] + input[6 + 3 * edge];
                if (!settled_backward[from] && candidate < backward[from]) backward[from] = candidate;
                if (forward[from] != inf && forward[from] + input[6 + 3 * edge] + backward[current] < best)
                    best = forward[from] + input[6 + 3 * edge] + backward[current];
            }
        }
    }
    return best == inf ? -1 : best;
}
