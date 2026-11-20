/* Binary lifting plus long-chain residual lookup for kth-ancestor queries. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_Q = 32, LOG_LEVELS = 6, MAX_INPUT_LENGTH = 130 };

typedef struct {
    int64_t parent[MAX_N], depth[MAX_N], height[MAX_N], heavy[MAX_N];
    int64_t chain_head[MAX_N], chain_position[MAX_N], chain_base[MAX_N];
    int64_t chain_nodes[MAX_N], head_ancestors[MAX_N];
    int64_t up[LOG_LEVELS][MAX_N];
} LongChainAncestorState;

static void write_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t long_chain_kth_ancestor(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != n + 1 + 2 * q) return -1;
    for (size_t vertex = 1; vertex < n; ++vertex)
        if (input[1 + vertex] < 0 || input[1 + vertex] >= (int64_t)vertex) return -1;
    const size_t query_start = n + 1;
    for (size_t query = 0; query < q; ++query) {
        const int64_t vertex = input[query_start + 2 * query];
        const int64_t distance = input[query_start + 2 * query + 1];
        if (vertex < 0 || vertex >= n_value || distance < 0 || distance >= MAX_N) return -1;
    }
    const size_t required = 8 * q;
    if (output == NULL || output_capacity < required) return -2;

    LongChainAncestorState state = {0};
    state.parent[0] = -1;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        state.heavy[vertex] = -1;
        state.chain_head[vertex] = -1;
        state.chain_base[vertex] = -1;
        if (vertex > 0) {
            state.parent[vertex] = input[1 + vertex];
            state.depth[vertex] = state.depth[state.parent[vertex]] + 1;
        }
        state.height[vertex] = 1;
    }
    for (size_t reverse = n; reverse > 1; --reverse) {
        const size_t vertex = reverse - 1;
        const int64_t parent = state.parent[vertex];
        const int64_t old = state.heavy[parent];
        if (old < 0 || state.height[vertex] > state.height[old] ||
            (state.height[vertex] == state.height[old] && (int64_t)vertex < old))
            state.heavy[parent] = (int64_t)vertex;
        if (state.height[vertex] + 1 > state.height[parent])
            state.height[parent] = state.height[vertex] + 1;
    }

    size_t pool = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        if (vertex == 0 || state.heavy[state.parent[vertex]] != (int64_t)vertex) {
            state.chain_base[vertex] = (int64_t)pool;
            int64_t current = (int64_t)vertex;
            size_t position = 0;
            while (current >= 0) {
                state.chain_head[current] = (int64_t)vertex;
                state.chain_position[current] = (int64_t)position;
                state.chain_nodes[pool + position] = current;
                current = state.heavy[current];
                ++position;
            }
            current = state.parent[vertex];
            for (size_t step = 0; step < position; ++step) {
                state.head_ancestors[pool + step] = current;
                current = current >= 0 ? state.parent[current] : -1;
            }
            pool += position;
        }
    }

    for (size_t vertex = 0; vertex < n; ++vertex) state.up[0][vertex] = state.parent[vertex];
    for (size_t level = 1; level < LOG_LEVELS; ++level) {
        for (size_t vertex = 0; vertex < n; ++vertex) {
            const int64_t halfway = state.up[level - 1][vertex];
            state.up[level][vertex] = halfway >= 0 ? state.up[level - 1][halfway] : -1;
        }
    }

    for (size_t query = 0; query < q; ++query) {
        const size_t vertex = (size_t)input[query_start + 2 * query];
        const size_t distance = (size_t)input[query_start + 2 * query + 1];
        int64_t answer = -1;
        if (distance <= (size_t)state.depth[vertex]) {
            if (distance == 0) {
                answer = (int64_t)vertex;
            } else {
                size_t level = 0;
                for (size_t value = distance; value > 1; value >>= 1) ++level;
                const int64_t jumped = state.up[level][vertex];
                const size_t remaining = distance - ((size_t)1 << level);
                const size_t head = (size_t)state.chain_head[jumped];
                const size_t position = (size_t)state.chain_position[jumped];
                const size_t base = (size_t)state.chain_base[head];
                if (remaining <= position) {
                    answer = state.chain_nodes[base + position - remaining];
                } else {
                    const size_t steps = remaining - position;
                    if (steps <= (size_t)state.height[head])
                        answer = state.head_ancestors[base + steps - 1];
                }
            }
        }
        write_i64(output, 8 * query, answer);
    }
    return (int64_t)required;
}
