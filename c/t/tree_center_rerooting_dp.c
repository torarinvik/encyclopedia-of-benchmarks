#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 2 * (MAX_N - 1))

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tree_center_rerooting_dp(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 2 * (n - 1)) return -1;

    size_t adjacency[MAX_N][MAX_N] = {{0}};
    size_t degree[MAX_N] = {0};
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const size_t offset = 1 + 2 * edge;
        const int64_t left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        adjacency[left][degree[left]++] = right;
        adjacency[right][degree[right]++] = left;
    }

    size_t parent[MAX_N];
    size_t order[MAX_N];
    size_t order_count = 1;
    for (size_t vertex = 0; vertex < n; ++vertex) parent[vertex] = MAX_N;
    parent[0] = MAX_N + 1;
    order[0] = 0;
    for (size_t position = 0; position < order_count; ++position) {
        const size_t vertex = order[position];
        for (size_t edge = 0; edge < degree[vertex]; ++edge) {
            const size_t child = adjacency[vertex][edge];
            if (child == parent[vertex]) continue;
            if (parent[child] != MAX_N) return -1;
            parent[child] = vertex;
            order[order_count++] = child;
        }
    }
    if (order_count != n) return -1;

    size_t down[MAX_N] = {0}, best[MAX_N] = {0}, second[MAX_N] = {0};
    size_t best_child[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) best_child[vertex] = MAX_N;
    for (size_t position = n; position > 0; --position) {
        const size_t vertex = order[position - 1];
        for (size_t edge = 0; edge < degree[vertex]; ++edge) {
            const size_t child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            const size_t branch = down[child] + 1;
            if (branch > best[vertex]) {
                second[vertex] = best[vertex];
                best[vertex] = branch;
                best_child[vertex] = child;
            } else if (branch > second[vertex]) {
                second[vertex] = branch;
            }
        }
        down[vertex] = best[vertex];
    }

    int outside[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) outside[vertex] = -1;
    for (size_t position = 0; position < n; ++position) {
        const size_t vertex = order[position];
        for (size_t edge = 0; edge < degree[vertex]; ++edge) {
            const size_t child = adjacency[vertex][edge];
            if (parent[child] != vertex) continue;
            const size_t sibling = best_child[vertex] == child ? second[vertex] : best[vertex];
            const int base = outside[vertex] > (int)sibling ? outside[vertex] : (int)sibling;
            outside[child] = base + 1;
        }
    }

    size_t radius = MAX_N;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const size_t outside_height = outside[vertex] < 0 ? 0 : (size_t)outside[vertex];
        const size_t eccentricity = down[vertex] > outside_height
            ? down[vertex] : outside_height;
        if (eccentricity < radius) radius = eccentricity;
    }
    int64_t centers[2];
    size_t center_count = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const size_t outside_height = outside[vertex] < 0 ? 0 : (size_t)outside[vertex];
        const size_t eccentricity = down[vertex] > outside_height
            ? down[vertex] : outside_height;
        if (eccentricity == radius) centers[center_count++] = (int64_t)vertex;
    }
    const size_t required = 8 * center_count;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < center_count; ++index)
        store_i64_le(output, 8 * index, centers[index]);
    return (int64_t)required;
}
