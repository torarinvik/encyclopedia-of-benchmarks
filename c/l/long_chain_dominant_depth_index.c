/* Long-chain DP for the smallest dominant subtree depth. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT_LENGTH = 65 };

typedef struct {
    int64_t parent[MAX_N], first_child[MAX_N], next_sibling[MAX_N];
    int64_t height[MAX_N], heavy[MAX_N], base[MAX_N], count[MAX_N];
    int64_t dominant_depth[MAX_N];
} LongChainState;

static void write_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t long_chain_dominant_depth_index(const int64_t *input, size_t length,
                                        uint8_t *output, size_t output_capacity) {
    if (input == NULL || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != (size_t)n_value) return -1;
    const size_t n = (size_t)n_value;
    for (size_t vertex = 1; vertex < n; ++vertex)
        if (input[vertex] < 0 || input[vertex] >= (int64_t)vertex) return -1;
    const size_t required = 8 * n;
    if (output == NULL || output_capacity < required) return -2;

    LongChainState state = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        state.first_child[vertex] = -1;
        state.heavy[vertex] = -1;
        state.height[vertex] = 1;
    }
    state.parent[0] = -1;
    for (size_t vertex = 1; vertex < n; ++vertex) {
        const int64_t parent = input[vertex];
        state.parent[vertex] = parent;
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = (int64_t)vertex;
    }

    for (size_t reverse = n; reverse > 0; --reverse) {
        const size_t vertex = reverse - 1;
        int64_t child = state.first_child[vertex];
        int64_t maximum_height = 0;
        while (child >= 0) {
            const int64_t child_height = state.height[child];
            if (child_height > maximum_height ||
                (child_height == maximum_height && child < state.heavy[vertex])) {
                maximum_height = child_height;
                state.heavy[vertex] = child;
            }
            child = state.next_sibling[child];
        }
        state.height[vertex] = maximum_height + 1;
    }

    int64_t pool_size = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        if (vertex == 0 || state.heavy[state.parent[vertex]] != (int64_t)vertex) {
            int64_t current = (int64_t)vertex;
            while (current >= 0) {
                state.base[current] = pool_size++;
                current = state.heavy[current];
            }
        }
    }

    for (size_t reverse = n; reverse > 0; --reverse) {
        const size_t vertex = reverse - 1;
        state.count[state.base[vertex]] = 1;
        int64_t best_depth = 0;
        int64_t best_count = 1;
        const int64_t heavy = state.heavy[vertex];
        if (heavy >= 0) {
            best_depth = state.dominant_depth[heavy] + 1;
            best_count = state.count[state.base[vertex] + best_depth];
        }
        for (int64_t child = state.first_child[vertex]; child >= 0;
             child = state.next_sibling[child]) {
            if (child == heavy) continue;
            for (int64_t child_depth = 0; child_depth < state.height[child]; ++child_depth) {
                const int64_t depth = child_depth + 1;
                const int64_t slot = state.base[vertex] + depth;
                const int64_t count = state.count[slot] + state.count[state.base[child] + child_depth];
                state.count[slot] = count;
                if (count > best_count || (count == best_count && depth < best_depth)) {
                    best_count = count;
                    best_depth = depth;
                }
            }
        }
        state.dominant_depth[vertex] = best_depth;
    }
    for (size_t vertex = 0; vertex < n; ++vertex)
        write_i64(output, 8 * vertex, state.dominant_depth[vertex]);
    return (int64_t)required;
}
