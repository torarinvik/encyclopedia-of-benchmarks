#include <stddef.h>
#include <stdint.h>

#define MAX_N 12
#define MAX_INPUT_VALUES (3 * MAX_N + 1)
#define MAX_OUTPUT_WORDS (MAX_N + 1)
#define MAX_WEIGHT INT64_C(1000000)

static int find_root(int parent[MAX_N], int vertex) {
    int root = vertex;
    while (parent[root] != root) root = parent[root];
    while (parent[vertex] != vertex) {
        int next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

static int compare_ratio(int64_t left_c, int64_t left_d,
                         int64_t right_c, int64_t right_d) {
    const int left_zero = left_c == 0 && left_d == 0;
    const int right_zero = right_c == 0 && right_d == 0;
    if (left_zero != right_zero) return left_zero ? -1 : 1;
    const int64_t lhs = left_c * right_d;
    const int64_t rhs = left_d * right_c;
    return (lhs > rhs) - (lhs < rhs);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t rooted_tree_topological_order_with_minimum_inversions(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != (size_t)(3 * n_value)) return -1;
    const int n = (int)n_value;

    int parent_vertex[MAX_N];
    parent_vertex[0] = -1;
    for (int vertex = 1; vertex < n; ++vertex) {
        const int64_t p = input[vertex];
        if (p < 0 || p >= vertex) return -1;
        parent_vertex[vertex] = (int)p;
    }

    int64_t original_c[MAX_N], original_d[MAX_N];
    int64_t aggregate_c[MAX_N], aggregate_d[MAX_N];
    int64_t sum_c = 0, sum_d = 0;
    const size_t c_start = (size_t)n;
    const size_t d_start = (size_t)(2 * n);
    for (int vertex = 0; vertex < n; ++vertex) {
        const int64_t c = input[c_start + (size_t)vertex];
        const int64_t d = input[d_start + (size_t)vertex];
        if (c < 0 || c > MAX_WEIGHT || d < 0 || d > MAX_WEIGHT) return -1;
        sum_c += c;
        sum_d += d;
        if (sum_c > MAX_WEIGHT || sum_d > MAX_WEIGHT) return -1;
        original_c[vertex] = aggregate_c[vertex] = c;
        original_d[vertex] = aggregate_d[vertex] = d;
    }

    int dsu_parent[MAX_N], component_label[MAX_N], active[MAX_N], link[MAX_N];
    for (int vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        component_label[vertex] = vertex;
        active[vertex] = vertex != 0;
        link[vertex] = vertex;
    }

    for (int step = 0; step < n - 1; ++step) {
        int selected = -1;
        for (int candidate = 1; candidate < n; ++candidate) {
            if (!active[candidate]) continue;
            if (selected < 0) {
                selected = candidate;
                continue;
            }
            const int comparison = compare_ratio(
                aggregate_c[candidate], aggregate_d[candidate],
                aggregate_c[selected], aggregate_d[selected]);
            if (comparison > 0 || (comparison == 0 && candidate > selected))
                selected = candidate;
        }
        if (selected < 0) return -1;

        const int parent_component = find_root(dsu_parent, parent_vertex[selected]);
        const int target = component_label[parent_component];
        const int selected_component = find_root(dsu_parent, selected);
        if (selected_component == parent_component) return -1;
        aggregate_c[target] += aggregate_c[selected];
        aggregate_d[target] += aggregate_d[selected];
        dsu_parent[selected_component] = parent_component;
        component_label[parent_component] = target;
        active[selected] = 0;
        if (target != 0) active[target] = 1;

        const int next = link[selected];
        link[selected] = link[target];
        link[target] = next;
    }

    int traversal[MAX_N];
    int count = 0;
    int vertex = link[0];
    while (count < n) {
        traversal[count++] = vertex;
        if (vertex == 0) break;
        vertex = link[vertex];
    }
    if (count != n || traversal[count - 1] != 0) return -1;

    int64_t words[MAX_OUTPUT_WORDS];
    int64_t prefix_d = 0, objective = 0;
    words[0] = 0;
    for (int index = 0; index < n; ++index) {
        const int ordered_vertex = traversal[n - 1 - index];
        words[index + 1] = ordered_vertex;
        objective += prefix_d * original_c[ordered_vertex];
        prefix_d += original_d[ordered_vertex];
    }
    words[0] = objective;

    const size_t output_bytes = (size_t)(n + 1) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t word = 0; word < (size_t)n + 1; ++word)
        store_i64_le(output, word * 8, words[word]);
    return (int64_t)output_bytes;
}
