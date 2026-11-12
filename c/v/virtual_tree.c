/* Build a bounded LCA-closed virtual tree in DFS order. */
#include <stddef.h>
#include <stdint.h>

#define VT_MAX_N 32
#define VT_MAX_K 32
#define VT_MAX_INPUT 66
#define VT_MAX_VIRTUAL 32
#define VT_MAX_CANDIDATES 64
#define VT_MAX_WORDS (1 + 3 * VT_MAX_VIRTUAL)

static void vt_put_i64(uint8_t *out, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static size_t vt_lca(size_t a, size_t b, const size_t *parent, const size_t *depth)
{
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) { a = parent[a]; b = parent[b]; }
    return a;
}

static int vt_ancestor(size_t a, size_t b, const size_t *tin, const size_t *tout)
{
    return tin[a] <= tin[b] && tin[b] < tout[a];
}

static void vt_sort(size_t *items, size_t count, const size_t *tin)
{
    for (size_t i = 1; i < count; ++i) {
        size_t value = items[i], j = i;
        while (j > 0 && tin[items[j - 1]] > tin[value]) { items[j] = items[j - 1]; --j; }
        items[j] = value;
    }
}

int64_t virtual_tree(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > VT_MAX_INPUT) return -1;
    int64_t n_value = input[0], k_value = input[1];
    if (n_value < 1 || n_value > VT_MAX_N || k_value < 0 || k_value > VT_MAX_K || k_value > n_value) return -1;
    size_t n = (size_t)n_value, k = (size_t)k_value;
    if (length != n + k + 1) return -1;

    size_t parent[VT_MAX_N] = {0}, depth[VT_MAX_N] = {0};
    size_t children[VT_MAX_N][VT_MAX_N] = {{0}}, child_count[VT_MAX_N] = {0};
    for (size_t v = 1; v < n; ++v) {
        int64_t p = input[v + 1];
        if (p < 0 || (uint64_t)p >= n || (size_t)p == v) return -1;
        parent[v] = (size_t)p;
        children[parent[v]][child_count[parent[v]]++] = v;
    }
    size_t marks[VT_MAX_K] = {0};
    for (size_t i = 0; i < k; ++i) {
        int64_t mark = input[n + 1 + i];
        if (mark < 0 || (uint64_t)mark >= n) return -1;
        marks[i] = (size_t)mark;
        for (size_t j = 0; j < i; ++j) if (marks[j] == marks[i]) return -1;
    }

    size_t tin[VT_MAX_N], tout[VT_MAX_N], node_stack[VT_MAX_N], next_stack[VT_MAX_N];
    for (size_t v = 0; v < n; ++v) tin[v] = tout[v] = SIZE_MAX;
    size_t timer = 0, top = 1, reached = 1;
    node_stack[0] = 0; next_stack[0] = 0; tin[0] = timer++;
    while (top != 0) {
        size_t frame = top - 1, vertex = node_stack[frame];
        if (next_stack[frame] == child_count[vertex]) { tout[vertex] = timer; --top; continue; }
        size_t child = children[vertex][next_stack[frame]++];
        if (tin[child] != SIZE_MAX) return -1;
        tin[child] = timer++; depth[child] = depth[vertex] + 1; ++reached;
        node_stack[top] = child; next_stack[top] = 0; ++top;
    }
    if (reached != n) return -1;

    int64_t words[VT_MAX_WORDS] = {0};
    size_t word_count = 1;
    if (k == 0) words[0] = 0;
    else {
        vt_sort(marks, k, tin);
        size_t nodes[VT_MAX_CANDIDATES], count = 0, stack[VT_MAX_VIRTUAL], stack_size = 0;
        nodes[count++] = 0;
        for (size_t i = 0; i < k; ++i) nodes[count++] = marks[i];
        for (size_t i = 1; i < k; ++i) nodes[count++] = vt_lca(marks[i - 1], marks[i], parent, depth);
        vt_sort(nodes, count, tin);
        size_t unique[VT_MAX_VIRTUAL], unique_count = 0;
        for (size_t i = 0; i < count; ++i)
            if (unique_count == 0 || unique[unique_count - 1] != nodes[i]) unique[unique_count++] = nodes[i];
        words[0] = (int64_t)unique_count;
        for (size_t i = 0; i < unique_count; ++i) {
            size_t vertex = unique[i];
            while (stack_size != 0 && !vt_ancestor(stack[stack_size - 1], vertex, tin, tout)) --stack_size;
            size_t vparent = stack_size == 0 ? vertex : stack[stack_size - 1];
            words[word_count++] = (int64_t)vertex;
            words[word_count++] = (int64_t)vparent;
            words[word_count++] = (int64_t)(depth[vertex] - depth[vparent]);
            stack[stack_size++] = vertex;
        }
    }
    size_t bytes = word_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < word_count; ++i) vt_put_i64(output, i * 8, words[i]);
    return (int64_t)bytes;
}
