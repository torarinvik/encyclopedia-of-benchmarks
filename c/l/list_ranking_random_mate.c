#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_ROUNDS = 32, MAX_INPUT = 275, MAX_OUTPUT = 64 };

static void store_le_i64(uint8_t *out, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        out[position + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t list_ranking_random_mate(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5u || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], head_value = input[1];
    if (n_value < 1 || n_value > MAX_N || head_value < 0 || head_value >= n_value)
        return -1;
    const size_t n = (size_t)n_value, head = (size_t)head_value;
    if (length < 3u + 2u * n) return -1;
    const int64_t rounds_value = input[2u + 2u * n];
    if (rounds_value < 0 || rounds_value > MAX_ROUNDS ||
        length != 3u + 2u * n + (size_t)rounds_value * n) return -1;
    const size_t rounds = (size_t)rounds_value;

    int64_t weight[MAX_N], successor[MAX_N];
    size_t indegree[MAX_N] = {0};
    size_t tail_count = 0;
    for (size_t node = 0; node < n; ++node) {
        weight[node] = input[2u + node];
        successor[node] = input[2u + n + node];
        if (weight[node] < 1 || weight[node] > 10000 ||
            successor[node] < -1 || successor[node] >= n_value) return -1;
        if (successor[node] == -1) ++tail_count;
        else if (++indegree[(size_t)successor[node]] > 1u) return -1;
    }
    if (tail_count != 1u || indegree[head] != 0u) return -1;
    const size_t coin_start = 3u + 2u * n;
    for (size_t index = 0; index < rounds * n; ++index)
        if (input[coin_start + index] < 0 || input[coin_start + index] > 1) return -1;

    size_t path_length = 0;
    int seen[MAX_N] = {0};
    int64_t node = head_value;
    while (node != -1) {
        const size_t index = (size_t)node;
        if (seen[index] || path_length == n) return -1;
        seen[index] = 1;
        ++path_length;
        node = successor[index];
    }
    if (path_length != n) return -1;

    int active[MAX_N];
    int removal_round[MAX_N];
    for (size_t index = 0; index < n; ++index) {
        active[index] = 1;
        removal_round[index] = -1;
    }
    for (size_t round = 0; round < rounds && successor[head] != -1; ++round) {
        int64_t old_successor[MAX_N], old_weight[MAX_N];
        int remove[MAX_N] = {0};
        for (size_t index = 0; index < n; ++index) {
            old_successor[index] = successor[index];
            old_weight[index] = weight[index];
        }
        const size_t coin_offset = coin_start + round * n;
        for (size_t index = 0; index < n; ++index) {
            const int64_t target = old_successor[index];
            if (active[index] && target != -1 && input[coin_offset + index] == 0 &&
                input[coin_offset + (size_t)target] == 1) {
                remove[(size_t)target] = 1;
                removal_round[(size_t)target] = (int)round;
            }
        }
        for (size_t index = 0; index < n; ++index) {
            const int64_t target = old_successor[index];
            if (active[index] && target != -1 && remove[(size_t)target]) {
                weight[index] = old_weight[index] + old_weight[(size_t)target];
                successor[index] = old_successor[(size_t)target];
            }
        }
        for (size_t index = 0; index < n; ++index)
            if (remove[index]) active[index] = 0;
    }
    if (successor[head] != -1) return -1;

    int64_t rank[MAX_N];
    for (size_t index = 0; index < n; ++index) rank[index] = weight[index];
    for (size_t round = rounds; round > 0; --round)
        for (size_t index = 0; index < n; ++index)
            if (removal_round[index] == (int)(round - 1u) && successor[index] != -1)
                rank[index] += rank[(size_t)successor[index]];

    const size_t output_bytes = 8u * n;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT];
    for (size_t index = 0; index < n; ++index)
        store_le_i64(staged, 8u * index, rank[index]);
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
