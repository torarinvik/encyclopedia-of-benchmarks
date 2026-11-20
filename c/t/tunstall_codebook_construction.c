/* Clean-room bounded Tunstall full-tree construction. */
#include <stddef.h>
#include <stdint.h>

#define MAX_S INT64_C(4222124650659840)
#define RESULT_FACTOR (MAX_S + INT64_C(1))

int64_t tunstall_codebook_construction(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 7) return -1;
    if (input[0] < 2 || input[0] > 4 || input[1] < 2 || input[1] > 4) return -1;
    const int k = (int)input[0];
    const int bits = (int)input[1];
    if (length != (size_t)k + 2) return -1;

    int64_t weights[4] = {0};
    int64_t total = 0;
    for (int i = 0; i < k; ++i) {
        const int64_t weight = input[2 + i];
        if (weight <= 0 || weight > 8) return -1;
        weights[i] = weight;
        total += weight;
    }
    if (total > 8) return -1;

    int64_t powers[17] = {0};
    powers[0] = 1;
    for (int i = 1; i <= 16; ++i) powers[i] = powers[i - 1] * total;
    const int cap = 1 << bits;
    int target = cap;
    while ((target - 1) % (k - 1) != 0) --target;

    int64_t product[31] = {0};
    int depth[31] = {0};
    uint64_t phrase_key[31] = {0};
    int leaves[16] = {0};
    int node_count = 1;
    int leaf_count = 0;
    for (int symbol = 0; symbol < k; ++symbol) {
        const int node = node_count++;
        product[node] = weights[symbol];
        depth[node] = 1;
        phrase_key[node] = (uint64_t)(symbol + 1) << 56;
        leaves[leaf_count++] = node;
    }

    int64_t scaled_expectation = powers[16];
    while (leaf_count < target) {
        int best_position = 0;
        int best_node = leaves[0];
        int64_t best_probability = product[best_node] * powers[15 - depth[best_node]];
        for (int position = 1; position < leaf_count; ++position) {
            const int candidate = leaves[position];
            const int64_t probability = product[candidate] * powers[15 - depth[candidate]];
            if (probability > best_probability ||
                (probability == best_probability && phrase_key[candidate] < phrase_key[best_node])) {
                best_position = position;
                best_node = candidate;
                best_probability = probability;
            }
        }

        scaled_expectation += product[best_node] * powers[16 - depth[best_node]];
        --leaf_count;
        leaves[best_position] = leaves[leaf_count];
        for (int symbol = 0; symbol < k; ++symbol) {
            const int child = node_count++;
            product[child] = product[best_node] * weights[symbol];
            depth[child] = depth[best_node] + 1;
            const int shift = 4 * (14 - depth[best_node]);
            phrase_key[child] = phrase_key[best_node] | ((uint64_t)(symbol + 1) << shift);
            leaves[leaf_count++] = child;
        }
    }

    const int64_t result = (int64_t)target * RESULT_FACTOR + scaled_expectation;
    return scaled_expectation <= MAX_S ? result : -1;
}
