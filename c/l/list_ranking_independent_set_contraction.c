#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_INPUT = 34, MAX_OUTPUT = 128 };

static void store_le_i64(uint8_t *out, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        out[position + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t list_ranking_independent_set_contraction(const int64_t *input,
                                                  size_t length,
                                                  uint8_t *output,
                                                  size_t capacity)
{
    if (input == NULL || length < 4u || length > MAX_INPUT) return -1;
    int64_t n_value = input[0], head_value = input[1];
    if (n_value < 1 || n_value > MAX_N || length != 2u + 2u * (size_t)n_value ||
        head_value < 0 || head_value >= n_value) return -1;
    size_t n = (size_t)n_value, head = (size_t)head_value;
    int64_t weight[MAX_N], successor[MAX_N];
    int indegree[MAX_N] = {0};
    size_t tail_count = 0;
    for (size_t node = 0; node < n; ++node) {
        weight[node] = input[2u + node];
        successor[node] = input[2u + n + node];
        if (weight[node] < 1 || weight[node] > 10000 ||
            successor[node] < -1 || successor[node] >= n_value) return -1;
        if (successor[node] == -1) {
            ++tail_count;
        } else if (++indegree[(size_t)successor[node]] > 1) {
            return -1;
        }
    }
    if (tail_count != 1u || indegree[head] != 0) return -1;

    size_t path[MAX_N], path_length = 0;
    int seen[MAX_N] = {0};
    int64_t node = head_value;
    while (node != -1) {
        size_t index = (size_t)node;
        if (seen[index] != 0 || path_length == n) return -1;
        seen[index] = 1;
        path[path_length++] = index;
        node = successor[index];
    }
    if (path_length != n) return -1;
    size_t output_bytes = 8u * n;
    if (output == NULL || capacity < output_bytes) return -2;

    size_t removed_node[MAX_N], removed_successor[MAX_N], removed_count = 0;
    int64_t old_successor_weight[MAX_N];
    while (path_length > 1u) {
        size_t counts[3] = {0, 0, 0};
        for (size_t position = 0; position + 1u < path_length; ++position)
            ++counts[position % 3u];
        size_t color = 0;
        for (size_t candidate = 1; candidate < 3u; ++candidate)
            if (counts[candidate] > counts[color]) color = candidate;

        size_t write = 0;
        for (size_t position = 0; position < path_length; ++position) {
            size_t current = path[position];
            if (position + 1u < path_length && position % 3u == color) {
                size_t next = path[position + 1u];
                removed_node[removed_count] = current;
                removed_successor[removed_count] = next;
                old_successor_weight[removed_count] = weight[next];
                ++removed_count;
                weight[next] += weight[current];
            } else {
                path[write++] = current;
            }
        }
        if (write == path_length) return -1;
        path_length = write;
    }

    int64_t rank[MAX_N] = {0};
    rank[path[0]] = weight[path[0]];
    while (removed_count > 0u) {
        --removed_count;
        size_t current = removed_node[removed_count];
        size_t next = removed_successor[removed_count];
        rank[current] = rank[next] - old_successor_weight[removed_count];
    }
    uint8_t staged[MAX_OUTPUT];
    for (size_t index = 0; index < n; ++index)
        store_le_i64(staged, 8u * index, rank[index]);
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
