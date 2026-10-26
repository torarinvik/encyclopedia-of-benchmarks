#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 8
#define MAX_INPUT 10
#define MAX_SUFFIXES (MAX_TEXT + 1)
#define MAX_NODES (2 * MAX_SUFFIXES - 1)
#define MAX_OUTPUT_WORDS (1 + 5 * MAX_NODES)

typedef struct {
    int64_t parent_rep;
    int64_t parent_depth;
    int64_t node_rep;
    int64_t node_depth;
    int64_t leaf_start;
} TreeRecord;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static int symbol_at(const int64_t *input, int text_length, int position)
{
    return position == text_length ? 0 : (int)input[position + 1];
}

static int suffix_less(const int64_t *input, int text_length, int left, int right)
{
    const int total = text_length + 1;
    while (left < total && right < total) {
        const int a = symbol_at(input, text_length, left);
        const int b = symbol_at(input, text_length, right);
        if (a != b) return a < b;
        ++left;
        ++right;
    }
    return left == total && right != total;
}

static int record_less(const TreeRecord *left, const TreeRecord *right)
{
    if (left->node_depth != right->node_depth) return left->node_depth < right->node_depth;
    if (left->node_rep != right->node_rep) return left->node_rep < right->node_rep;
    return left->leaf_start < right->leaf_start;
}

int64_t suffix_tree_from_sa_lcp(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 0 || n_raw > MAX_TEXT || length != (size_t)n_raw + 1) return -1;
    const int n = (int)n_raw;
    for (int i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 255) return -1;

    const int suffix_count = n + 1;
    int suffix_array[MAX_SUFFIXES];
    int lcp[MAX_SUFFIXES] = {0};
    for (int i = 0; i < suffix_count; ++i) suffix_array[i] = i;
    for (int i = 1; i < suffix_count; ++i) {
        const int value = suffix_array[i];
        int j = i;
        while (j > 0 && suffix_less(input, n, value, suffix_array[j - 1])) {
            suffix_array[j] = suffix_array[j - 1];
            --j;
        }
        suffix_array[j] = value;
    }
    for (int rank = 1; rank < suffix_count; ++rank) {
        int left = suffix_array[rank - 1], right = suffix_array[rank], common = 0;
        while (left + common < suffix_count && right + common < suffix_count
            && symbol_at(input, n, left + common) == symbol_at(input, n, right + common)) ++common;
        lcp[rank] = common;
    }

    int parent[MAX_NODES], depth[MAX_NODES], representative[MAX_NODES], leaf[MAX_NODES], last_child[MAX_NODES];
    int stack[MAX_NODES];
    int node_count = 1, stack_size = 1;
    parent[0] = -1; depth[0] = 0; representative[0] = -1; leaf[0] = -1; last_child[0] = -1;
    stack[0] = 0;
    for (int rank = 0; rank < suffix_count; ++rank) {
        if (rank > 0) {
            const int common = lcp[rank];
            while (stack_size > 1 && depth[stack[stack_size - 1]] > common) --stack_size;
            const int top = stack[stack_size - 1];
            if (depth[top] < common) {
                const int old_child = last_child[top];
                if (old_child < 0) return -1;
                const int internal = node_count++;
                parent[internal] = top; depth[internal] = common;
                representative[internal] = representative[old_child]; leaf[internal] = -1;
                last_child[internal] = old_child;
                parent[old_child] = internal;
                last_child[top] = internal;
                stack[stack_size++] = internal;
            }
        }
        const int owner = stack[stack_size - 1];
        const int suffix_start = suffix_array[rank];
        const int new_leaf = node_count++;
        parent[new_leaf] = owner; depth[new_leaf] = suffix_count - suffix_start;
        representative[new_leaf] = suffix_start; leaf[new_leaf] = suffix_start;
        last_child[new_leaf] = -1;
        last_child[owner] = new_leaf;
    }

    TreeRecord records[MAX_NODES];
    for (int node = 0; node < node_count; ++node) {
        if (node == 0) records[node] = (TreeRecord){-1, -1, -1, 0, -1};
        else {
            const int p = parent[node];
            records[node] = (TreeRecord){representative[p], depth[p], representative[node], depth[node], leaf[node]};
        }
    }
    for (int i = 1; i < node_count; ++i) {
        const TreeRecord value = records[i];
        int j = i;
        while (j > 0 && record_less(&value, &records[j - 1])) { records[j] = records[j - 1]; --j; }
        records[j] = value;
    }
    int64_t staged[MAX_OUTPUT_WORDS] = {0};
    staged[0] = node_count;
    size_t words = 1;
    for (int node = 0; node < node_count; ++node) {
        staged[words++] = records[node].parent_rep;
        staged[words++] = records[node].parent_depth;
        staged[words++] = records[node].node_rep;
        staged[words++] = records[node].node_depth;
        staged[words++] = records[node].leaf_start;
    }
    const size_t bytes = words * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t word = 0; word < words; ++word) store_i64_le(output, word * 8, staged[word]);
    return (int64_t)bytes;
}
