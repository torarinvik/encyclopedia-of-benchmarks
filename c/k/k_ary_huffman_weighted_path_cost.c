#include <stddef.h>
#include <stdint.h>

#define KARY_MAX_SYMBOLS 10
#define KARY_MAX_NODES 16

int64_t k_ary_huffman_weighted_path_cost(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > 13) return -1;
    const int64_t arity_value = input[0];
    const int64_t count_value = input[1];
    if ((arity_value != 3 && arity_value != 4) || count_value < 1 || count_value > KARY_MAX_SYMBOLS) return -1;
    const size_t arity = (size_t)arity_value;
    const size_t count = (size_t)count_value;
    if (length != count + 2) return -1;
    if (count > 1 && (count - 1) % (arity - 1) != 0) return -1;

    int64_t weights[KARY_MAX_NODES] = {0};
    uint8_t active[KARY_MAX_NODES] = {0};
    for (size_t index = 0; index < count; ++index) {
        const int64_t weight = input[index + 2];
        if (weight < 0 || weight > 1000) return -1;
        weights[index] = weight;
        active[index] = 1;
    }

    size_t node_count = count;
    size_t active_count = count;
    int64_t cost = 0;
    while (active_count > 1) {
        int64_t combined = 0;
        for (size_t pick = 0; pick < arity; ++pick) {
            size_t best = KARY_MAX_NODES;
            for (size_t index = 0; index < node_count; ++index) {
                if (!active[index]) continue;
                if (best == KARY_MAX_NODES) best = index;
                else if (weights[index] < weights[best]
                         || (weights[index] == weights[best] && index < best)) best = index;
            }
            if (best == KARY_MAX_NODES) return -1;
            combined += weights[best];
            active[best] = 0;
            --active_count;
        }
        cost += combined;
        weights[node_count] = combined;
        active[node_count] = 1;
        ++node_count;
        ++active_count;
    }
    return cost;
}
