#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_DEGREE 255
#define MAX_NODE_KEYS (2 * MIN_DEGREE - 1)
#define MAX_NODE_CHILDREN (2 * MIN_DEGREE)
#define MAX_NODE_COUNT 32
#define MAX_INSERTS 2048
#define MAX_QUERIES 1024
#define MAX_DELETES 1024
#define MAX_INPUT_LENGTH 4096
#define MAX_OUTPUT_VALUES (2 + MAX_QUERIES + MAX_INSERTS)

typedef struct {
    int32_t keys[MAX_NODE_COUNT][MAX_NODE_KEYS];
    size_t children[MAX_NODE_COUNT][MAX_NODE_CHILDREN];
    size_t key_count[MAX_NODE_COUNT];
    bool leaf[MAX_NODE_COUNT];
    size_t used_nodes;
    size_t root;
} BTree;

static size_t new_node(BTree *tree, bool leaf)
{
    if (tree->used_nodes >= MAX_NODE_COUNT) return MAX_NODE_COUNT;
    const size_t node = tree->used_nodes++;
    tree->key_count[node] = 0;
    tree->leaf[node] = leaf;
    return node;
}

static bool search_key(const BTree *tree, int32_t key)
{
    size_t node = tree->root;
    for (;;) {
        size_t index = 0;
        while (index < tree->key_count[node] && key > tree->keys[node][index]) ++index;
        if (index < tree->key_count[node] && key == tree->keys[node][index]) return true;
        if (tree->leaf[node]) return false;
        node = tree->children[node][index];
    }
}

static bool split_child(BTree *tree, size_t parent, size_t child_index)
{
    const size_t sibling = new_node(tree, tree->leaf[tree->children[parent][child_index]]);
    if (sibling == MAX_NODE_COUNT) return false;
    const size_t child = tree->children[parent][child_index];
    for (size_t i = 0; i < MIN_DEGREE - 1; ++i)
        tree->keys[sibling][i] = tree->keys[child][i + MIN_DEGREE];
    if (!tree->leaf[child])
        for (size_t i = 0; i < MIN_DEGREE; ++i)
            tree->children[sibling][i] = tree->children[child][i + MIN_DEGREE];
    tree->key_count[sibling] = MIN_DEGREE - 1;

    const size_t parent_count = tree->key_count[parent];
    for (size_t i = parent_count + 1; i > child_index + 1; --i)
        tree->children[parent][i] = tree->children[parent][i - 1];
    tree->children[parent][child_index + 1] = sibling;
    for (size_t i = parent_count; i > child_index; --i)
        tree->keys[parent][i] = tree->keys[parent][i - 1];
    tree->keys[parent][child_index] = tree->keys[child][MIN_DEGREE - 1];
    tree->key_count[child] = MIN_DEGREE - 1;
    tree->key_count[parent] = parent_count + 1;
    return true;
}

static bool insert_non_full(BTree *tree, size_t node, int32_t key)
{
    size_t index = tree->key_count[node];
    if (tree->leaf[node]) {
        while (index > 0 && key < tree->keys[node][index - 1]) {
            tree->keys[node][index] = tree->keys[node][index - 1];
            --index;
        }
        tree->keys[node][index] = key;
        ++tree->key_count[node];
        return true;
    }
    while (index > 0 && key < tree->keys[node][index - 1]) --index;
    if (tree->key_count[tree->children[node][index]] == MAX_NODE_KEYS) {
        if (!split_child(tree, node, index)) return false;
        if (key > tree->keys[node][index]) ++index;
    }
    return insert_non_full(tree, tree->children[node][index], key);
}

static bool insert_key(BTree *tree, int32_t key)
{
    if (tree->key_count[tree->root] == MAX_NODE_KEYS) {
        const size_t old_root = tree->root;
        const size_t root = new_node(tree, false);
        if (root == MAX_NODE_COUNT) return false;
        tree->children[root][0] = old_root;
        tree->root = root;
        if (!split_child(tree, root, 0)) return false;
    }
    return insert_non_full(tree, tree->root, key);
}

static int32_t predecessor(const BTree *tree, size_t node)
{
    while (!tree->leaf[node]) node = tree->children[node][tree->key_count[node]];
    return tree->keys[node][tree->key_count[node] - 1];
}

static int32_t successor(const BTree *tree, size_t node)
{
    while (!tree->leaf[node]) node = tree->children[node][0];
    return tree->keys[node][0];
}

static void merge_children(BTree *tree, size_t parent, size_t index)
{
    const size_t left = tree->children[parent][index];
    const size_t right = tree->children[parent][index + 1];
    size_t left_count = tree->key_count[left];
    tree->keys[left][left_count++] = tree->keys[parent][index];
    for (size_t i = 0; i < tree->key_count[right]; ++i)
        tree->keys[left][left_count + i] = tree->keys[right][i];
    if (!tree->leaf[left])
        for (size_t i = 0; i <= tree->key_count[right]; ++i)
            tree->children[left][left_count + i] = tree->children[right][i];
    tree->key_count[left] = left_count + tree->key_count[right];

    const size_t parent_count = tree->key_count[parent];
    for (size_t i = index + 1; i < parent_count; ++i)
        tree->keys[parent][i - 1] = tree->keys[parent][i];
    for (size_t i = index + 2; i <= parent_count; ++i)
        tree->children[parent][i - 1] = tree->children[parent][i];
    tree->key_count[parent] = parent_count - 1;
}

static void borrow_from_previous(BTree *tree, size_t parent, size_t index)
{
    const size_t child = tree->children[parent][index];
    const size_t sibling = tree->children[parent][index - 1];
    const size_t child_count = tree->key_count[child];
    for (size_t i = child_count; i > 0; --i) tree->keys[child][i] = tree->keys[child][i - 1];
    if (!tree->leaf[child])
        for (size_t i = child_count + 1; i > 0; --i)
            tree->children[child][i] = tree->children[child][i - 1];
    tree->keys[child][0] = tree->keys[parent][index - 1];
    if (!tree->leaf[child])
        tree->children[child][0] = tree->children[sibling][tree->key_count[sibling]];
    tree->keys[parent][index - 1] = tree->keys[sibling][tree->key_count[sibling] - 1];
    ++tree->key_count[child];
    --tree->key_count[sibling];
}

static void borrow_from_next(BTree *tree, size_t parent, size_t index)
{
    const size_t child = tree->children[parent][index];
    const size_t sibling = tree->children[parent][index + 1];
    const size_t child_count = tree->key_count[child];
    const size_t sibling_count = tree->key_count[sibling];
    tree->keys[child][child_count] = tree->keys[parent][index];
    if (!tree->leaf[child]) tree->children[child][child_count + 1] = tree->children[sibling][0];
    tree->keys[parent][index] = tree->keys[sibling][0];
    for (size_t i = 1; i < sibling_count; ++i) tree->keys[sibling][i - 1] = tree->keys[sibling][i];
    if (!tree->leaf[sibling])
        for (size_t i = 1; i <= sibling_count; ++i)
            tree->children[sibling][i - 1] = tree->children[sibling][i];
    ++tree->key_count[child];
    --tree->key_count[sibling];
}

static void fill_child(BTree *tree, size_t parent, size_t index)
{
    if (index > 0 && tree->key_count[tree->children[parent][index - 1]] >= MIN_DEGREE)
        borrow_from_previous(tree, parent, index);
    else if (index < tree->key_count[parent] && tree->key_count[tree->children[parent][index + 1]] >= MIN_DEGREE)
        borrow_from_next(tree, parent, index);
    else
        merge_children(tree, parent, index < tree->key_count[parent] ? index : index - 1);
}

static bool delete_key_from_node(BTree *tree, size_t node, int32_t key)
{
    size_t index = 0;
    while (index < tree->key_count[node] && tree->keys[node][index] < key) ++index;
    if (index < tree->key_count[node] && tree->keys[node][index] == key) {
        if (tree->leaf[node]) {
            for (size_t i = index + 1; i < tree->key_count[node]; ++i)
                tree->keys[node][i - 1] = tree->keys[node][i];
            --tree->key_count[node];
        } else {
            const size_t left = tree->children[node][index];
            const size_t right = tree->children[node][index + 1];
            if (tree->key_count[left] >= MIN_DEGREE) {
                const int32_t replacement = predecessor(tree, left);
                tree->keys[node][index] = replacement;
                return delete_key_from_node(tree, left, replacement);
            }
            if (tree->key_count[right] >= MIN_DEGREE) {
                const int32_t replacement = successor(tree, right);
                tree->keys[node][index] = replacement;
                return delete_key_from_node(tree, right, replacement);
            }
            merge_children(tree, node, index);
            return delete_key_from_node(tree, left, key);
        }
        return true;
    }
    if (tree->leaf[node]) return false;
    const bool was_last_child = index == tree->key_count[node];
    if (tree->key_count[tree->children[node][index]] < MIN_DEGREE)
        fill_child(tree, node, index);
    if (was_last_child && index > tree->key_count[node]) --index;
    return delete_key_from_node(tree, tree->children[node][index], key);
}

static bool delete_key(BTree *tree, int32_t key)
{
    if (!delete_key_from_node(tree, tree->root, key)) return false;
    if (tree->key_count[tree->root] == 0 && !tree->leaf[tree->root])
        tree->root = tree->children[tree->root][0];
    return true;
}

static void write_in_order(const BTree *tree, size_t node, int64_t *result, size_t *length)
{
    for (size_t i = 0; i < tree->key_count[node]; ++i) {
        if (!tree->leaf[node]) write_in_order(tree, tree->children[node][i], result, length);
        result[(*length)++] = tree->keys[node][i];
    }
    if (!tree->leaf[node])
        write_in_order(tree, tree->children[node][tree->key_count[node]], result, length);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

extern "C" int64_t btree_unique_key_set(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_INSERTS) return -1;
    const size_t insert_count = (size_t)input[0];
    const size_t query_count_offset = 1 + insert_count;
    if (query_count_offset >= length) return -1;
    if (input[query_count_offset] < 0 || input[query_count_offset] > MAX_QUERIES) return -1;
    const size_t query_count = (size_t)input[query_count_offset];
    const size_t delete_count_offset = query_count_offset + 1 + query_count;
    if (delete_count_offset >= length) return -1;
    if (input[delete_count_offset] < 0 || input[delete_count_offset] > MAX_DELETES) return -1;
    const size_t delete_count = (size_t)input[delete_count_offset];
    if (length != 3 + insert_count + query_count + delete_count) return -1;

    BTree tree = {0};
    tree.used_nodes = 1;
    tree.root = 0;
    tree.leaf[0] = true;
    for (size_t i = 0; i < insert_count; ++i) {
        const int64_t raw_key = input[1 + i];
        if (raw_key < INT32_MIN || raw_key > INT32_MAX) return -1;
        const int32_t key = (int32_t)raw_key;
        if (search_key(&tree, key) || !insert_key(&tree, key)) return -1;
    }

    int64_t result[MAX_OUTPUT_VALUES];
    size_t result_length = 0;
    result[result_length++] = (int64_t)query_count;
    const size_t query_offset = query_count_offset + 1;
    for (size_t i = 0; i < query_count; ++i) {
        const int64_t raw_key = input[query_offset + i];
        if (raw_key < INT32_MIN || raw_key > INT32_MAX) return -1;
        result[result_length++] = search_key(&tree, (int32_t)raw_key) ? 1 : 0;
    }

    const size_t delete_offset = delete_count_offset + 1;
    for (size_t i = 0; i < delete_count; ++i) {
        const int64_t raw_key = input[delete_offset + i];
        if (raw_key < INT32_MIN || raw_key > INT32_MAX || !delete_key(&tree, (int32_t)raw_key)) return -1;
    }

    const size_t final_count_slot = result_length++;
    write_in_order(&tree, tree.root, result, &result_length);
    result[final_count_slot] = (int64_t)(result_length - final_count_slot - 1);
    const size_t output_bytes = result_length * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < result_length; ++i) store_i64_le(output, i * 8, result[i]);
    return (int64_t)output_bytes;
}
