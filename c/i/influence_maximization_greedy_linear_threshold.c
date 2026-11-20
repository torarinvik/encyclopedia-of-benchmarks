#include <stddef.h>
#include <stdint.h>

#define LT_MAX_N 8
#define LT_MAX_M 24
#define LT_MAX_WORLDS 8
#define LT_WEIGHT_SCALE 256
#define LT_MAX_INPUT 141

static void lt_put_i64(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

static int lt_reachable_count(int n, const int parents[LT_MAX_N], uint16_t seeds) {
    int queue[LT_MAX_N];
    int head = 0, tail = 0;
    uint16_t reached = seeds;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((seeds & (uint16_t)(1u << vertex)) != 0) queue[tail++] = vertex;
    }
    while (head < tail) {
        const int source = queue[head++];
        for (int target = 0; target < n; ++target) {
            const uint16_t bit = (uint16_t)(1u << target);
            if (parents[target] == source && (reached & bit) == 0) {
                reached |= bit;
                queue[tail++] = target;
            }
        }
    }
    int total = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((reached & (uint16_t)(1u << vertex)) != 0) ++total;
    }
    return total;
}

int64_t influence_maximization_greedy_linear_threshold(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > LT_MAX_INPUT) return -1;
    const int64_t n0 = input[0], m0 = input[1], k0 = input[2], worlds0 = input[3];
    if (n0 < 1 || n0 > LT_MAX_N || m0 < 0 || m0 > LT_MAX_M
            || k0 < 0 || k0 > n0 || worlds0 < 1 || worlds0 > LT_MAX_WORLDS) return -1;
    const int n = (int)n0, m = (int)m0, k = (int)k0, worlds = (int)worlds0;
    const size_t expected_length = 4 + 3 * (size_t)m + (size_t)worlds * (size_t)n;
    if (length != expected_length) return -1;

    int edge_u[LT_MAX_M] = {0}, edge_v[LT_MAX_M] = {0};
    int edge_weight[LT_MAX_M] = {0}, incoming_sum[LT_MAX_N] = {0};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u = input[4 + 3 * (size_t)edge];
        const int64_t v = input[5 + 3 * (size_t)edge];
        const int64_t weight = input[6 + 3 * (size_t)edge];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v
                || weight < 0 || weight > LT_WEIGHT_SCALE) return -1;
        for (int prior = 0; prior < edge; ++prior) {
            if (edge_u[prior] == u && edge_v[prior] == v) return -1;
        }
        incoming_sum[v] += (int)weight;
        if (incoming_sum[v] > LT_WEIGHT_SCALE) return -1;
        edge_u[edge] = (int)u;
        edge_v[edge] = (int)v;
        edge_weight[edge] = (int)weight;
    }

    int draws[LT_MAX_WORLDS][LT_MAX_N] = {{0}};
    const size_t draws_start = 4 + 3 * (size_t)m;
    for (int world = 0; world < worlds; ++world) {
        for (int vertex = 0; vertex < n; ++vertex) {
            const int64_t draw = input[draws_start + (size_t)world * (size_t)n + (size_t)vertex];
            if (draw < 0 || draw >= LT_WEIGHT_SCALE) return -1;
            draws[world][vertex] = (int)draw;
        }
    }

    int parents[LT_MAX_WORLDS][LT_MAX_N];
    for (int world = 0; world < worlds; ++world) {
        for (int target = 0; target < n; ++target) {
            parents[world][target] = -1;
            const int ticket = draws[world][target];
            int offset = 0;
            for (int edge = 0; edge < m; ++edge) {
                if (edge_v[edge] != target) continue;
                const int next_offset = offset + edge_weight[edge];
                if (offset <= ticket && ticket < next_offset) {
                    parents[world][target] = edge_u[edge];
                    break;
                }
                offset = next_offset;
            }
        }
    }

    uint16_t selected = 0;
    int chosen[LT_MAX_N] = {0}, scores[LT_MAX_N] = {0};
    for (int round = 0; round < k; ++round) {
        int current[LT_MAX_WORLDS] = {0};
        for (int world = 0; world < worlds; ++world) {
            current[world] = lt_reachable_count(n, parents[world], selected);
        }
        int best_node = -1, best_score = -1;
        for (int candidate = 0; candidate < n; ++candidate) {
            const uint16_t bit = (uint16_t)(1u << candidate);
            if ((selected & bit) != 0) continue;
            int score = 0;
            for (int world = 0; world < worlds; ++world) {
                score += lt_reachable_count(n, parents[world], (uint16_t)(selected | bit))
                        - current[world];
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

    const size_t bytes = (size_t)(1 + 2 * k) * 8;
    if (output == NULL || capacity < bytes) return -2;
    lt_put_i64(output, 0, k);
    for (int round = 0; round < k; ++round) {
        lt_put_i64(output, (size_t)(1 + 2 * round), chosen[round]);
        lt_put_i64(output, (size_t)(2 + 2 * round), scores[round]);
    }
    return (int64_t)bytes;
}
