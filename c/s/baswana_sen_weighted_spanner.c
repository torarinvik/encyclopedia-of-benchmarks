#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 28, MAX_INPUT = 90 };

static int edge_before(size_t a, size_t b, const int64_t *u,
                       const int64_t *v, const int64_t *weight) {
    return weight[a] < weight[b] ||
           (weight[a] == weight[b] && u[a] < u[b]) ||
           (weight[a] == weight[b] && u[a] == u[b] && v[a] < v[b]);
}

int64_t baswana_sen_weighted_spanner(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], k = input[2];
    if (n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || k < 2 || k > 3)
        return -1;
    const size_t n = (size_t)n64, m = (size_t)m64, rounds = (size_t)(k - 1);
    if (length != 3 + rounds + 3 * m) return -1;
    int64_t masks[MAX_N] = {0};
    for (size_t round = 0; round < rounds; ++round) {
        masks[round] = input[3 + round];
        if (masks[round] < 0 || masks[round] >= (INT64_C(1) << n64)) return -1;
    }
    int64_t edge_u[MAX_M], edge_v[MAX_M], edge_w[MAX_M];
    uint8_t active[MAX_M] = {0}, selected[MAX_M] = {0};
    const size_t edge_offset = 3 + rounds;
    for (size_t e = 0; e < m; ++e) {
        edge_u[e] = input[edge_offset + 3 * e];
        edge_v[e] = input[edge_offset + 3 * e + 1];
        edge_w[e] = input[edge_offset + 3 * e + 2];
        if (edge_u[e] < 0 || edge_v[e] <= edge_u[e] || edge_v[e] >= n64 ||
            edge_w[e] < 1 || edge_w[e] > 32) return -1;
        for (size_t prior = 0; prior < e; ++prior)
            if (edge_u[prior] == edge_u[e] && edge_v[prior] == edge_v[e]) return -1;
        active[e] = 1;
    }
    if (output == NULL || capacity < m) return -2;

    int cluster[MAX_N], next_cluster[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) cluster[vertex] = (int)vertex;
    for (size_t round = 0; round < rounds; ++round) {
        uint8_t sampled[MAX_N] = {0}, remove[MAX_M] = {0};
        for (size_t vertex = 0; vertex < n; ++vertex) next_cluster[vertex] = -1;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            const int center = cluster[vertex];
            if (center >= 0 && ((masks[round] >> center) & 1) != 0)
                sampled[center] = 1;
        }
        for (size_t vertex = 0; vertex < n; ++vertex) {
            const int center = cluster[vertex];
            if (center >= 0 && sampled[center]) next_cluster[vertex] = center;
        }

        for (size_t vertex = 0; vertex < n; ++vertex) {
            const int old_center = cluster[vertex];
            if (old_center < 0 || sampled[old_center]) continue;
            size_t best_sampled = m;
            for (size_t e = 0; e < m; ++e) {
                if (!active[e] || (edge_u[e] != (int64_t)vertex && edge_v[e] != (int64_t)vertex)) continue;
                const size_t other = (size_t)(edge_u[e] == (int64_t)vertex ? edge_v[e] : edge_u[e]);
                const int destination = cluster[other];
                if (destination >= 0 && sampled[destination] &&
                    (best_sampled == m || edge_before(e, best_sampled, edge_u, edge_v, edge_w)))
                    best_sampled = e;
            }

            if (best_sampled == m) {
                for (size_t destination = 0; destination < n; ++destination) {
                    size_t least = m;
                    for (size_t e = 0; e < m; ++e) {
                        if (!active[e] || (edge_u[e] != (int64_t)vertex && edge_v[e] != (int64_t)vertex)) continue;
                        const size_t other = (size_t)(edge_u[e] == (int64_t)vertex ? edge_v[e] : edge_u[e]);
                        if (cluster[other] == (int)destination &&
                            (least == m || edge_before(e, least, edge_u, edge_v, edge_w))) least = e;
                    }
                    if (least != m) {
                        selected[least] = 1;
                        for (size_t e = 0; e < m; ++e) {
                            if (!active[e] || (edge_u[e] != (int64_t)vertex && edge_v[e] != (int64_t)vertex)) continue;
                            const size_t other = (size_t)(edge_u[e] == (int64_t)vertex ? edge_v[e] : edge_u[e]);
                            if (cluster[other] == (int)destination) remove[e] = 1;
                        }
                    }
                }
                continue;
            }

            const size_t best_other = (size_t)(edge_u[best_sampled] == (int64_t)vertex
                                                    ? edge_v[best_sampled] : edge_u[best_sampled]);
            const int chosen_center = cluster[best_other];
            next_cluster[vertex] = chosen_center;
            selected[best_sampled] = 1;
            for (size_t e = 0; e < m; ++e) {
                if (!active[e] || (edge_u[e] != (int64_t)vertex && edge_v[e] != (int64_t)vertex)) continue;
                const size_t other = (size_t)(edge_u[e] == (int64_t)vertex ? edge_v[e] : edge_u[e]);
                if (cluster[other] == chosen_center) remove[e] = 1;
            }
            for (size_t destination = 0; destination < n; ++destination) {
                if ((int)destination == chosen_center) continue;
                size_t least = m;
                for (size_t e = 0; e < m; ++e) {
                    if (!active[e] || (edge_u[e] != (int64_t)vertex && edge_v[e] != (int64_t)vertex)) continue;
                    const size_t other = (size_t)(edge_u[e] == (int64_t)vertex ? edge_v[e] : edge_u[e]);
                    if (cluster[other] == (int)destination &&
                        (least == m || edge_before(e, least, edge_u, edge_v, edge_w))) least = e;
                }
                if (least != m && edge_w[least] < edge_w[best_sampled]) {
                    selected[least] = 1;
                    for (size_t e = 0; e < m; ++e) {
                        if (!active[e] || (edge_u[e] != (int64_t)vertex && edge_v[e] != (int64_t)vertex)) continue;
                        const size_t other = (size_t)(edge_u[e] == (int64_t)vertex ? edge_v[e] : edge_u[e]);
                        if (cluster[other] == (int)destination) remove[e] = 1;
                    }
                }
            }
        }

        for (size_t e = 0; e < m; ++e) if (remove[e]) active[e] = 0;
        for (size_t e = 0; e < m; ++e) {
            const size_t u = (size_t)edge_u[e], v = (size_t)edge_v[e];
            if (active[e] && next_cluster[u] >= 0 && next_cluster[u] == next_cluster[v]) active[e] = 0;
        }
        for (size_t vertex = 0; vertex < n; ++vertex) cluster[vertex] = next_cluster[vertex];
    }

    for (size_t vertex = 0; vertex < n; ++vertex) {
        if (cluster[vertex] < 0) continue;
        for (size_t destination = 0; destination < n; ++destination) {
            size_t least = m;
            for (size_t e = 0; e < m; ++e) {
                if (!active[e] || (edge_u[e] != (int64_t)vertex && edge_v[e] != (int64_t)vertex)) continue;
                const size_t other = (size_t)(edge_u[e] == (int64_t)vertex ? edge_v[e] : edge_u[e]);
                if (cluster[other] == (int)destination &&
                    (least == m || edge_before(e, least, edge_u, edge_v, edge_w))) least = e;
            }
            if (least != m) selected[least] = 1;
        }
    }
    for (size_t e = 0; e < m; ++e) output[e] = selected[e];
    return (int64_t)m;
}
