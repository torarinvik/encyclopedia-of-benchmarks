#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_INPUT_VALUES (1 + 3 * (MAX_N - 1))
#define MAX_OUTPUT_VALUES (2 + MAX_N)

static size_t find_root(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static void traverse(size_t n, size_t start, const uint8_t adjacent[MAX_N][MAX_N],
    const int64_t weight[MAX_N][MAX_N], int64_t distance[MAX_N],
    int64_t parent[MAX_N]) {
    size_t stack[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        distance[vertex] = -1;
        parent[vertex] = -1;
    }
    size_t top = 0;
    stack[top++] = start;
    distance[start] = 0;
    while (top > 0) {
        const size_t vertex = stack[--top];
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || distance[neighbor] >= 0) continue;
            distance[neighbor] = distance[vertex] + weight[vertex][neighbor];
            parent[neighbor] = (int64_t)vertex;
            stack[top++] = neighbor;
        }
    }
}

static size_t farthest(size_t n, const int64_t distance[MAX_N]) {
    size_t best = 0;
    for (size_t vertex = 1; vertex < n; ++vertex) {
        if (distance[vertex] > distance[best] ||
            (distance[vertex] == distance[best] && vertex < best)) best = vertex;
    }
    return best;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tree_diameter(const int64_t *input, size_t length,
                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + 3 * (n - 1)) return -1;

    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int64_t weight[MAX_N][MAX_N] = {{0}};
    size_t dsu_parent[MAX_N], dsu_size[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const size_t offset = 1 + 3 * edge;
        const int64_t left_value = input[offset];
        const int64_t right_value = input[offset + 1];
        const int64_t edge_weight = input[offset + 2];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value ||
            edge_weight < 1 || edge_weight > INT64_C(1000000000)) return -1;
        size_t left = (size_t)left_value, right = (size_t)right_value;
        size_t root_left = find_root(dsu_parent, left);
        size_t root_right = find_root(dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const size_t temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = adjacent[right][left] = 1;
        weight[left][right] = weight[right][left] = edge_weight;
    }

    int64_t distance[MAX_N], parent[MAX_N];
    traverse(n, 0, adjacent, weight, distance, parent);
    const size_t first_endpoint = farthest(n, distance);
    traverse(n, first_endpoint, adjacent, weight, distance, parent);
    const size_t second_endpoint = farthest(n, distance);
    size_t reverse_path[MAX_N];
    size_t path_length = 0;
    int64_t current = (int64_t)second_endpoint;
    while (current >= 0) {
        reverse_path[path_length++] = (size_t)current;
        if ((size_t)current == first_endpoint) break;
        current = parent[(size_t)current];
    }

    int64_t staged[MAX_OUTPUT_VALUES];
    size_t used = 0;
    staged[used++] = distance[second_endpoint];
    staged[used++] = (int64_t)path_length;
    for (size_t position = 0; position < path_length; ++position)
        staged[used++] = (int64_t)reverse_path[path_length - 1 - position];
    const size_t required = 8 * used;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < used; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return (int64_t)required;
}
