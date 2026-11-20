#include <stddef.h>
#include <stdint.h>

enum { MAX_TREE_NODES = 15, MAX_TOTAL_NODES = 30, MAX_PARSEABLE_LENGTH = 93 };

static int valid_tree(const int64_t *input, size_t offset, size_t node_count) {
    int64_t visited[MAX_TREE_NODES] = {0};
    int64_t parents[MAX_TREE_NODES] = {0};
    size_t stack[MAX_TREE_NODES] = {0};
    size_t top = 1;
    size_t reached = 0;
    while (top > 0) {
        const size_t node = stack[--top];
        if (node >= node_count || visited[node]) return 0;
        visited[node] = 1;
        ++reached;
        const size_t base = offset + 3 * node;
        const int64_t left = input[base + 1];
        const int64_t right = input[base + 2];
        if (left == -1 && right == -1) continue;
        if (left < 0 || right < 0 || (uint64_t)left >= node_count ||
            (uint64_t)right >= node_count || left == right || left == 0 || right == 0) return 0;
        if (++parents[(size_t)left] != 1 || ++parents[(size_t)right] != 1) return 0;
        stack[top++] = (size_t)right;
        stack[top++] = (size_t)left;
    }
    if (reached != node_count || parents[0] != 0) return 0;
    for (size_t node = 1; node < node_count; ++node)
        if (parents[node] != 1) return 0;
    return 1;
}

int64_t same_fringe_leaf_iterator(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_a_word = input[0];
    const int64_t n_b_word = input[1];
    if (n_a_word < 1 || n_a_word > MAX_TREE_NODES ||
        n_b_word < 1 || n_b_word > MAX_TREE_NODES) return -1;
    const size_t n_a = (size_t)n_a_word;
    const size_t n_b = (size_t)n_b_word;
    if (n_a + n_b > MAX_TOTAL_NODES || length != 2 + 3 * (n_a + n_b)) return -1;
    const size_t offset_a = 2;
    const size_t offset_b = 2 + 3 * n_a;
    if (!valid_tree(input, offset_a, n_a) || !valid_tree(input, offset_b, n_b)) return -1;

    size_t stack_a[MAX_TREE_NODES] = {0};
    size_t stack_b[MAX_TREE_NODES] = {0};
    size_t top_a = 1;
    size_t top_b = 1;
    while (1) {
        int have_a = 0;
        int have_b = 0;
        int64_t leaf_a = 0;
        int64_t leaf_b = 0;
        while (top_a > 0 && !have_a) {
            const size_t node = stack_a[--top_a];
            const size_t base = offset_a + 3 * node;
            const int64_t left = input[base + 1];
            const int64_t right = input[base + 2];
            if (left == -1) {
                leaf_a = input[base];
                have_a = 1;
            } else {
                stack_a[top_a++] = (size_t)right;
                stack_a[top_a++] = (size_t)left;
            }
        }
        while (top_b > 0 && !have_b) {
            const size_t node = stack_b[--top_b];
            const size_t base = offset_b + 3 * node;
            const int64_t left = input[base + 1];
            const int64_t right = input[base + 2];
            if (left == -1) {
                leaf_b = input[base];
                have_b = 1;
            } else {
                stack_b[top_b++] = (size_t)right;
                stack_b[top_b++] = (size_t)left;
            }
        }
        if (!have_a || !have_b) return have_a == have_b ? 1 : 0;
        if (leaf_a != leaf_b) return 0;
    }
    return -1;
}
