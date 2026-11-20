#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 24
#define MAX_WORLDS 8
#define MAX_INPUT 77

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[word * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

static int reachable_count(int n, int m, int world, uint16_t seeds,
                           const int edge_u[MAX_M], const int edge_v[MAX_M],
                           const int masks[MAX_M]) {
    int queue[MAX_N];
    int head = 0;
    int tail = 0;
    uint16_t reached = seeds;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((seeds & (uint16_t)(1u << vertex)) != 0) queue[tail++] = vertex;
    }
    while (head < tail) {
        int source = queue[head++];
        for (int edge = 0; edge < m; ++edge) {
            int target = edge_v[edge];
            uint16_t bit = (uint16_t)(1u << target);
            if (edge_u[edge] == source && (masks[edge] & (1 << world)) != 0
                    && (reached & bit) == 0) {
                reached |= bit;
                queue[tail++] = target;
            }
        }
    }
    int count = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((reached & (uint16_t)(1u << vertex)) != 0) ++count;
    }
    return count;
}

int64_t influence_maximization_greedy_live_edge(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t n0 = input[0], m0 = input[1], k0 = input[2], worlds0 = input[3];
    if (n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > MAX_M
            || k0 < 0 || k0 > n0 || worlds0 < 1 || worlds0 > MAX_WORLDS
            || length != 4 + 3 * (size_t)m0) return -1;
    int n = (int)n0, m = (int)m0, k = (int)k0, worlds = (int)worlds0;
    int edge_u[MAX_M] = {0}, edge_v[MAX_M] = {0}, masks[MAX_M] = {0};
    int allowed = (1 << worlds) - 1;
    for (int edge = 0; edge < m; ++edge) {
        int64_t u = input[4 + 3 * edge];
        int64_t v = input[5 + 3 * edge];
        int64_t mask = input[6 + 3 * edge];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v
                || mask < 0 || mask > allowed) return -1;
        for (int earlier = 0; earlier < edge; ++earlier) {
            if (edge_u[earlier] == u && edge_v[earlier] == v) return -1;
        }
        edge_u[edge] = (int)u;
        edge_v[edge] = (int)v;
        masks[edge] = (int)mask;
    }

    uint16_t selected = 0;
    int chosen[MAX_N] = {0}, scores[MAX_N] = {0};
    for (int round = 0; round < k; ++round) {
        int current[MAX_WORLDS] = {0};
        for (int world = 0; world < worlds; ++world) {
            current[world] = reachable_count(n, m, world, selected, edge_u, edge_v, masks);
        }
        int best_node = -1, best_score = -1;
        for (int candidate = 0; candidate < n; ++candidate) {
            uint16_t bit = (uint16_t)(1u << candidate);
            if ((selected & bit) != 0) continue;
            int score = 0;
            for (int world = 0; world < worlds; ++world) {
                score += reachable_count(n, m, world, (uint16_t)(selected | bit),
                                         edge_u, edge_v, masks) - current[world];
            }
            if (score > best_score) {
                best_node = candidate;
                best_score = score;
            }
        }
        if (best_node < 0) return -1;
        selected |= (uint16_t)(1u << best_node);
        chosen[round] = best_node;
        scores[round] = best_score;
    }

    size_t bytes = (size_t)(1 + 2 * k) * 8;
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, k);
    for (int round = 0; round < k; ++round) {
        put_i64(output, (size_t)(1 + 2 * round), chosen[round]);
        put_i64(output, (size_t)(2 + 2 * round), scores[round]);
    }
    return (int64_t)bytes;
}
