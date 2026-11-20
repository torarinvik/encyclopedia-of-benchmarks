/* Minimum walk length covering all vertices via multi-source product BFS. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 10, MAX_STATES = 10240, MAX_PARSEABLE_LENGTH = 93 };

int64_t shortest_path_visiting_all_nodes(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < 0 || m_value > 45) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    if (m > n * (n - 1) / 2 || length != 2 + 2 * m) return -1;

    uint16_t adjacency[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u_value = input[2 + 2 * edge];
        const int64_t v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        const size_t u = (size_t)u_value;
        const size_t v = (size_t)v_value;
        const uint16_t u_bit = (uint16_t)(1u << v);
        const uint16_t v_bit = (uint16_t)(1u << u);
        if ((adjacency[u] & u_bit) != 0) return -1;
        adjacency[u] |= u_bit;
        adjacency[v] |= v_bit;
    }

    uint16_t reached = 1u;
    for (;;) {
        const uint16_t previous = reached;
        for (size_t v = 0; v < n; ++v)
            if ((reached & (uint16_t)(1u << v)) != 0) reached |= adjacency[v];
        if (reached == previous) break;
    }
    const uint16_t full = (uint16_t)((1u << n) - 1u);
    if (reached != full) return -1;

    int16_t distance[MAX_STATES];
    uint16_t queue[MAX_STATES];
    const size_t state_count = ((size_t)1 << n) * n;
    for (size_t i = 0; i < state_count; ++i) distance[i] = -1;
    size_t head = 0, tail = 0;
    for (size_t start = 0; start < n; ++start) {
        const size_t mask = (size_t)1 << start;
        const size_t state = mask * n + start;
        distance[state] = 0;
        queue[tail++] = (uint16_t)state;
    }
    while (head < tail) {
        const size_t state = queue[head++];
        const size_t mask = state / n;
        const size_t vertex = state % n;
        if (mask == full) return distance[state];
        for (size_t next = 0; next < n; ++next) {
            if ((adjacency[vertex] & (uint16_t)(1u << next)) == 0) continue;
            const size_t next_mask = mask | ((size_t)1 << next);
            const size_t next_state = next_mask * n + next;
            if (distance[next_state] >= 0) continue;
            distance[next_state] = (int16_t)(distance[state] + 1);
            queue[tail++] = (uint16_t)next_state;
        }
    }
    return -1;
}
