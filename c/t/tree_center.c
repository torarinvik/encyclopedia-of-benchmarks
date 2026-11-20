#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_LENGTH (1 + 2 * (MAX_N - 1))

static size_t find_root(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tree_center(const int64_t *input, size_t length,
                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 2 * (n - 1)) return -1;

    size_t adjacency[MAX_N][MAX_N] = {{0}};
    size_t adjacency_count[MAX_N] = {0};
    size_t degree[MAX_N] = {0};
    size_t parent[MAX_N], component_size[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        parent[vertex] = vertex;
        component_size[vertex] = 1;
    }
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const size_t offset = 1 + 2 * edge;
        const int64_t left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        size_t root_left = find_root(parent, left), root_right = find_root(parent, right);
        if (root_left == root_right) return -1;
        if (component_size[root_left] < component_size[root_right]) {
            const size_t temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        parent[root_right] = root_left;
        component_size[root_left] += component_size[root_right];
        adjacency[left][adjacency_count[left]++] = right;
        adjacency[right][adjacency_count[right]++] = left;
        ++degree[left];
        ++degree[right];
    }
    if (n > 1 && component_size[find_root(parent, 0)] != n) return -1;

    uint8_t active[MAX_N] = {0};
    size_t leaves[MAX_N], leaf_count = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        active[vertex] = 1;
        if (degree[vertex] <= 1) leaves[leaf_count++] = vertex;
    }
    size_t remaining = n;
    while (remaining > 2) {
        for (size_t index = 0; index < leaf_count; ++index) active[leaves[index]] = 0;
        remaining -= leaf_count;
        for (size_t index = 0; index < leaf_count; ++index) {
            const size_t leaf = leaves[index];
            for (size_t edge = 0; edge < adjacency_count[leaf]; ++edge) {
                const size_t neighbor = adjacency[leaf][edge];
                if (active[neighbor]) --degree[neighbor];
            }
        }
        if (remaining <= 2) break;
        leaf_count = 0;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if (active[vertex] && degree[vertex] == 1) leaves[leaf_count++] = vertex;
    }

    int64_t centers[2];
    size_t center_count = 0;
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (active[vertex]) centers[center_count++] = (int64_t)vertex;
    const size_t required = 8 * center_count;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < center_count; ++index)
        store_i64_le(output, 8 * index, centers[index]);
    return (int64_t)required;
}
