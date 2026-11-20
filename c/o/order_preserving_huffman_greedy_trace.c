#include <stddef.h>
#include <stdint.h>

static void store_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t order_preserving_huffman_greedy_trace(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 10) return -1;
    int64_t raw_n = input[0];
    if (raw_n < 2 || raw_n > 8 || length != (size_t)raw_n + 1) return -1;
    size_t n = (size_t)raw_n;
    int64_t node_weight[15] = {0};
    int left[15], right[15], active[8];
    for (size_t i = 0; i < 15; ++i) left[i] = right[i] = -1;
    int64_t total = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t w = input[i + 1];
        if (w < 1 || w > 15) return -1;
        node_weight[i] = w;
        total += w;
        active[i] = (int)i;
    }
    if (total > 120) return -1;

    size_t active_count = n, next_node = n;
    while (active_count > 1) {
        size_t pair = 0;
        int64_t best = node_weight[active[0]] + node_weight[active[1]];
        for (size_t i = 1; i + 1 < active_count; ++i) {
            int64_t candidate = node_weight[active[i]] + node_weight[active[i + 1]];
            if (candidate < best) { best = candidate; pair = i; }
        }
        int a = active[pair], b = active[pair + 1];
        node_weight[next_node] = best;
        left[next_node] = a;
        right[next_node] = b;
        for (size_t i = pair; i + 2 < active_count; ++i) active[i] = active[i + 2];
        active_count -= 2;
        for (size_t i = active_count; i > pair; --i) active[i] = active[i - 1];
        active[pair] = (int)next_node;
        ++active_count;
        ++next_node;
    }

    int depths[8] = {0}, stack_node[16], stack_depth[16];
    size_t top = 1;
    stack_node[0] = active[0]; stack_depth[0] = 0;
    while (top > 0) {
        --top;
        int node = stack_node[top], depth = stack_depth[top];
        if ((size_t)node < n) depths[node] = depth;
        else {
            stack_node[top] = left[node]; stack_depth[top] = depth + 1; ++top;
            stack_node[top] = right[node]; stack_depth[top] = depth + 1; ++top;
        }
    }

    int64_t staged[10];
    staged[0] = raw_n;
    int64_t cost = 0;
    for (size_t i = 0; i < n; ++i) cost += input[i + 1] * (int64_t)depths[i];
    staged[1] = cost;
    for (size_t i = 0; i < n; ++i) staged[i + 2] = depths[i];
    size_t needed = 8 * (n + 2);
    uint8_t bytes[80];
    for (size_t i = 0; i < n + 2; ++i) store_i64(bytes, 8 * i, staged[i]);
    if (output == NULL || capacity < needed) return -2;
    for (size_t i = 0; i < needed; ++i) output[i] = bytes[i];
    return (int64_t)needed;
}
