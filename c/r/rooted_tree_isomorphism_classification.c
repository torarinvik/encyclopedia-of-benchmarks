#include <stddef.h>
#include <stdint.h>

#define MAX_TREES 16
#define MAX_TREE_VERTICES 32
#define MAX_TOTAL_VERTICES 128
#define MAX_INPUT_LENGTH (1 + 2 * MAX_TREES * MAX_TREE_VERTICES)

typedef struct {
    size_t child_count;
    size_t child_types[MAX_TREE_VERTICES];
} TreeSignature;

static size_t intern_signature(TreeSignature *signatures, size_t *signature_count,
                               const size_t *children, size_t child_count)
{
    for (size_t signature = 0; signature < *signature_count; ++signature) {
        if (signatures[signature].child_count != child_count) continue;
        size_t index = 0;
        while (index < child_count && signatures[signature].child_types[index] == children[index]) ++index;
        if (index == child_count) return signature;
    }
    if (*signature_count >= MAX_TOTAL_VERTICES) return MAX_TOTAL_VERTICES;
    const size_t result = *signature_count;
    signatures[result].child_count = child_count;
    for (size_t index = 0; index < child_count; ++index)
        signatures[result].child_types[index] = children[index];
    *signature_count += 1;
    return result;
}

static int64_t canonical_root_type(const uint32_t *adjacency, size_t vertex_count,
                                  size_t root, TreeSignature *signatures,
                                  size_t *signature_count)
{
    size_t parent[MAX_TREE_VERTICES];
    size_t order[MAX_TREE_VERTICES];
    size_t stack[MAX_TREE_VERTICES];
    size_t type[MAX_TREE_VERTICES];
    uint8_t visited[MAX_TREE_VERTICES] = {0};
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = MAX_TREE_VERTICES;
    parent[root] = root;
    visited[root] = 1;
    size_t stack_size = 1, order_size = 0;
    stack[0] = root;
    while (stack_size != 0) {
        const size_t vertex = stack[--stack_size];
        order[order_size++] = vertex;
        for (size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
            const uint32_t bit = UINT32_C(1) << (uint32_t)neighbor;
            if ((adjacency[vertex] & bit) == 0 || neighbor == parent[vertex]) continue;
            if (visited[neighbor]) return -1;
            visited[neighbor] = 1;
            parent[neighbor] = vertex;
            stack[stack_size++] = neighbor;
        }
    }
    if (order_size != vertex_count) return -1;

    for (size_t reverse = order_size; reverse > 0; --reverse) {
        const size_t vertex = order[reverse - 1];
        size_t children[MAX_TREE_VERTICES];
        size_t child_count = 0;
        for (size_t candidate = 0; candidate < vertex_count; ++candidate) {
            if (candidate != vertex && parent[candidate] == vertex)
                children[child_count++] = type[candidate];
        }
        for (size_t index = 1; index < child_count; ++index) {
            const size_t value = children[index];
            size_t position = index;
            while (position > 0 && children[position - 1] > value) {
                children[position] = children[position - 1];
                --position;
            }
            children[position] = value;
        }
        type[vertex] = intern_signature(signatures, signature_count, children, child_count);
        if (type[vertex] >= MAX_TOTAL_VERTICES) return -1;
    }
    return (int64_t)type[root];
}

int64_t rooted_tree_isomorphism_classification(const int64_t *values, size_t length,
                                                uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t tree_count_value = values[0];
    if (tree_count_value < 1 || tree_count_value > MAX_TREES) return -1;
    const size_t tree_count = (size_t)tree_count_value;
    TreeSignature signatures[MAX_TOTAL_VERTICES] = {0};
    size_t signature_count = 0;
    size_t root_types[MAX_TREES];
    uint8_t labels[MAX_TREES];
    size_t position = 1, total_vertices = 0, class_count = 0;

    for (size_t tree = 0; tree < tree_count; ++tree) {
        if (position + 2 > length) return -1;
        const int64_t vertex_count_value = values[position++];
        const int64_t root_value = values[position++];
        if (vertex_count_value < 1 || vertex_count_value > MAX_TREE_VERTICES) return -1;
        const size_t vertex_count = (size_t)vertex_count_value;
        if (root_value < 0 || root_value >= vertex_count_value) return -1;
        total_vertices += vertex_count;
        if (total_vertices > MAX_TOTAL_VERTICES) return -1;
        const size_t edge_count = vertex_count - 1;
        if (2 * edge_count > length - position) return -1;

        uint32_t adjacency[MAX_TREE_VERTICES] = {0};
        for (size_t edge = 0; edge < edge_count; ++edge) {
            const int64_t left_value = values[position++];
            const int64_t right_value = values[position++];
            if (left_value < 0 || right_value < 0 || left_value >= vertex_count_value ||
                right_value >= vertex_count_value || left_value == right_value) return -1;
            const size_t left = (size_t)left_value;
            const size_t right = (size_t)right_value;
            const uint32_t left_bit = UINT32_C(1) << (uint32_t)left;
            const uint32_t right_bit = UINT32_C(1) << (uint32_t)right;
            if ((adjacency[left] & right_bit) != 0) return -1;
            adjacency[left] |= right_bit;
            adjacency[right] |= left_bit;
        }

        const int64_t root_type = canonical_root_type(adjacency, vertex_count,
            (size_t)root_value, signatures, &signature_count);
        if (root_type < 0) return -1;
        root_types[tree] = (size_t)root_type;
        size_t prior = 0;
        while (prior < tree && root_types[prior] != root_types[tree]) ++prior;
        if (prior < tree) labels[tree] = labels[prior];
        else labels[tree] = (uint8_t)class_count++;
    }
    if (position != length) return -1;
    if (output == NULL || output_capacity < tree_count) return -2;
    for (size_t tree = 0; tree < tree_count; ++tree) output[tree] = labels[tree];
    return (int64_t)tree_count;
}
