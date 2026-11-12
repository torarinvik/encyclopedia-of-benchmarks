#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 12, MAX_INPUT = 2 + 3 * MAX_M, INF = 1000000000 };

int64_t undirected_chinese_postman(const int64_t *input, size_t length) {
    if (!input || length < 2) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M) return -1;
    const int n = (int)input[0], m = (int)input[1];
    if (length != (size_t)(2 + 3 * m) || length > MAX_INPUT) return -1;
    if (n == 1) return m == 0 ? 0 : -1;
    if (m < n - 1) return -1;

    int64_t distance[MAX_N][MAX_N];
    int degree[MAX_N] = {0};
    unsigned char seen[MAX_N][MAX_N] = {{0}};
    int64_t total_weight = 0;
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v)
            distance[u][v] = u == v ? 0 : INF;

    for (int edge = 0; edge < m; ++edge) {
        const int64_t u_value = input[2 + 3 * edge];
        const int64_t v_value = input[3 + 3 * edge];
        const int64_t weight = input[4 + 3 * edge];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n ||
            u_value == v_value || weight < 1 || weight > 1000) return -1;
        const int u = (int)u_value, v = (int)v_value;
        if (seen[u][v]) return -1;
        seen[u][v] = seen[v][u] = 1;
        distance[u][v] = distance[v][u] = weight;
        ++degree[u];
        ++degree[v];
        total_weight += weight;
    }

    for (int middle = 0; middle < n; ++middle)
        for (int source = 0; source < n; ++source)
            for (int target = 0; target < n; ++target) {
                const int64_t candidate = distance[source][middle] + distance[middle][target];
                if (candidate < distance[source][target]) distance[source][target] = candidate;
            }
    for (int vertex = 0; vertex < n; ++vertex) if (distance[0][vertex] >= INF) return -1;

    int odd[MAX_N], odd_count = 0;
    for (int vertex = 0; vertex < n; ++vertex)
        if (degree[vertex] & 1) odd[odd_count++] = vertex;
    int64_t pairing[1 << MAX_N];
    const int state_count = 1 << odd_count;
    for (int mask = 0; mask < state_count; ++mask) pairing[mask] = INF;
    pairing[0] = 0;
    for (int mask = 1; mask < state_count; ++mask) {
        int first = 0;
        while ((mask & (1 << first)) == 0) ++first;
        const int first_bit = 1 << first;
        for (int partner = first + 1; partner < odd_count; ++partner) {
            const int partner_bit = 1 << partner;
            if ((mask & partner_bit) == 0) continue;
            const int remaining = mask ^ first_bit ^ partner_bit;
            const int64_t candidate = distance[odd[first]][odd[partner]] + pairing[remaining];
            if (candidate < pairing[mask]) pairing[mask] = candidate;
        }
    }
    return total_weight + pairing[state_count - 1];
}
