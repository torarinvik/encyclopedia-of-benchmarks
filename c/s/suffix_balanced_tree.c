#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 32, MAX_INPUT = 33 };
#define TAG_LIMIT (UINT64_C(1) << 62)
typedef struct {
    int64_t text[MAX_TEXT];
    int left[MAX_TEXT], right[MAX_TEXT], size[MAX_TEXT];
    uint64_t tag[MAX_TEXT];
    int buffer[MAX_TEXT], buffered;
} suffix_tree;

static int node_size(const suffix_tree *tree, int node) { return node < 0 ? 0 : tree->size[node]; }
static int suffix_less(const suffix_tree *tree, int x, int y, int n) {
    if (tree->text[x] != tree->text[y]) return tree->text[x] < tree->text[y];
    uint64_t next_x = x + 1 < n ? tree->tag[x + 1] : 0;
    uint64_t next_y = y + 1 < n ? tree->tag[y + 1] : 0;
    return next_x < next_y;
}
static void flatten(suffix_tree *tree, int root) {
    if (root < 0) return;
    flatten(tree, tree->left[root]);
    tree->buffer[tree->buffered++] = root;
    flatten(tree, tree->right[root]);
}
static int build_balanced(suffix_tree *tree, int lo, int hi, uint64_t low, uint64_t high) {
    if (lo >= hi) return -1;
    int mid = lo + (hi - lo) / 2;
    int root = tree->buffer[mid];
    uint64_t tag = low + (high - low) / 2;
    tree->tag[root] = tag;
    tree->left[root] = build_balanced(tree, lo, mid, low, tag);
    tree->right[root] = build_balanced(tree, mid + 1, hi, tag, high);
    tree->size[root] = 1 + node_size(tree, tree->left[root]) + node_size(tree, tree->right[root]);
    return root;
}
static int rebuild(suffix_tree *tree, int root, uint64_t low, uint64_t high) {
    tree->buffered = 0;
    flatten(tree, root);
    return build_balanced(tree, 0, tree->buffered, low, high);
}
static int insert_suffix(suffix_tree *tree, int root, int pos, int n, uint64_t low, uint64_t high) {
    if (root < 0) {
        tree->left[pos] = tree->right[pos] = -1;
        tree->size[pos] = 1;
        tree->tag[pos] = low + (high - low) / 2;
        return pos;
    }
    if (suffix_less(tree, pos, root, n))
        tree->left[root] = insert_suffix(tree, tree->left[root], pos, n, low, tree->tag[root]);
    else
        tree->right[root] = insert_suffix(tree, tree->right[root], pos, n, tree->tag[root], high);
    int left_size = node_size(tree, tree->left[root]);
    int right_size = node_size(tree, tree->right[root]);
    tree->size[root] = 1 + left_size + right_size;
    int heavy = left_size > right_size ? left_size : right_size;
    if (4 * heavy >= 3 * tree->size[root]) return rebuild(tree, root, low, high);
    return root;
}
static void inorder(const suffix_tree *tree, int root, int64_t answer[MAX_TEXT], size_t *count) {
    if (root < 0) return;
    inorder(tree, tree->left[root], answer, count);
    answer[(*count)++] = root;
    inorder(tree, tree->right[root], answer, count);
}
static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t suffix_balanced_tree(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_TEXT || length != 1 + (size_t)n_value) return -1;
    int n = (int)n_value;
    for (int i = 0; i < n; ++i) if (input[1 + i] < 0 || input[1 + i] > 255) return -1;
    size_t required = 8 * (size_t)n;
    if (output == NULL || capacity < required) return -2;
    if (n == 0) return 0;
    suffix_tree tree = {0};
    for (int i = 0; i < n; ++i) tree.text[i] = input[1 + i];
    int root = -1;
    for (int pos = n - 1; pos >= 0; --pos) root = insert_suffix(&tree, root, pos, n, 0, TAG_LIMIT);
    int64_t answer[MAX_TEXT]; size_t answer_count = 0;
    inorder(&tree, root, answer, &answer_count);
    for (size_t i = 0; i < answer_count; ++i) store_le(output, 8 * i, answer[i]);
    return (int64_t)required;
}
