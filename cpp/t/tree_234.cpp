#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 128, MAX_NODES = 2049, MAX_PARSEABLE_INPUT_LENGTH = 258,
       MAX_OUTPUT_WORDS = 130, MAX_OUTPUT_BYTES = 1040 };

typedef struct {
    int64_t keys[3];
    int children[4];
    int key_count;
    int leaf;
} TreeNode;

typedef struct {
    TreeNode nodes[MAX_NODES];
    int node_count;
    int root;
    int64_t final_keys[MAX_OPERATIONS];
    size_t final_count;
} TreeContext;

static int new_node(TreeContext *tree, int leaf)
{
    int index = tree->node_count++;
    TreeNode *node = &tree->nodes[index];
    node->key_count = 0;
    node->leaf = leaf;
    for (int child = 0; child < 4; ++child) node->children[child] = -1;
    return index;
}

static int contains(const TreeContext *tree, int node_index, int64_t key)
{
    if (node_index < 0) return 0;
    const TreeNode *node = &tree->nodes[node_index];
    int index = 0;
    while (index < node->key_count && key > node->keys[index]) ++index;
    if (index < node->key_count && key == node->keys[index]) return 1;
    return !node->leaf && contains(tree, node->children[index], key);
}

static void split_child(TreeContext *tree, int parent_index, int child_position)
{
    TreeNode *parent = &tree->nodes[parent_index];
    int child_index = parent->children[child_position];
    int right_index = new_node(tree, tree->nodes[child_index].leaf);
    TreeNode *left = &tree->nodes[child_index];
    TreeNode *right = &tree->nodes[right_index];
    right->key_count = 1;
    right->keys[0] = left->keys[2];
    if (!left->leaf) {
        right->children[0] = left->children[2];
        right->children[1] = left->children[3];
    }
    int64_t middle = left->keys[1];
    left->key_count = 1;
    for (int index = parent->key_count; index > child_position; --index)
        parent->keys[index] = parent->keys[index - 1];
    for (int index = parent->key_count + 1; index > child_position + 1; --index)
        parent->children[index] = parent->children[index - 1];
    parent->keys[child_position] = middle;
    parent->children[child_position + 1] = right_index;
    parent->key_count++;
}

static void insert_nonfull(TreeContext *tree, int node_index, int64_t key)
{
    TreeNode *node = &tree->nodes[node_index];
    int index = node->key_count - 1;
    if (node->leaf) {
        while (index >= 0 && key < node->keys[index]) {
            node->keys[index + 1] = node->keys[index];
            --index;
        }
        node->keys[index + 1] = key;
        node->key_count++;
        return;
    }
    while (index >= 0 && key < node->keys[index]) --index;
    ++index;
    if (tree->nodes[node->children[index]].key_count == 3) {
        split_child(tree, node_index, index);
        node = &tree->nodes[node_index];
        if (key > node->keys[index]) ++index;
    }
    insert_nonfull(tree, tree->nodes[node_index].children[index], key);
}

static void insert_key(TreeContext *tree, int64_t key)
{
    if (contains(tree, tree->root, key)) return;
    if (tree->root < 0) {
        tree->root = new_node(tree, 1);
        tree->nodes[tree->root].keys[0] = key;
        tree->nodes[tree->root].key_count = 1;
        return;
    }
    if (tree->nodes[tree->root].key_count == 3) {
        int old_root = tree->root;
        int new_root = new_node(tree, 0);
        tree->nodes[new_root].children[0] = old_root;
        tree->root = new_root;
        split_child(tree, new_root, 0);
    }
    insert_nonfull(tree, tree->root, key);
}

static int find_key(const TreeNode *node, int64_t key)
{
    int index = 0;
    while (index < node->key_count && node->keys[index] < key) ++index;
    return index < node->key_count && node->keys[index] == key ? index : -1;
}

static int64_t predecessor(const TreeContext *tree, int node_index)
{
    const TreeNode *node = &tree->nodes[node_index];
    while (!node->leaf) node = &tree->nodes[node->children[node->key_count]];
    return node->keys[node->key_count - 1];
}

static int64_t successor(const TreeContext *tree, int node_index)
{
    const TreeNode *node = &tree->nodes[node_index];
    while (!node->leaf) node = &tree->nodes[node->children[0]];
    return node->keys[0];
}

static int merge_children(TreeContext *tree, int parent_index, int key_index)
{
    TreeNode *parent = &tree->nodes[parent_index];
    int left_index = parent->children[key_index];
    int right_index = parent->children[key_index + 1];
    TreeNode *left = &tree->nodes[left_index];
    TreeNode *right = &tree->nodes[right_index];
    int left_count = left->key_count;
    left->keys[left_count] = parent->keys[key_index];
    for (int index = 0; index < right->key_count; ++index)
        left->keys[left_count + 1 + index] = right->keys[index];
    if (!left->leaf) {
        for (int index = 0; index <= right->key_count; ++index)
            left->children[left_count + 1 + index] = right->children[index];
    }
    left->key_count = left_count + 1 + right->key_count;
    for (int index = key_index; index < parent->key_count - 1; ++index)
        parent->keys[index] = parent->keys[index + 1];
    for (int index = key_index + 1; index < parent->key_count; ++index)
        parent->children[index] = parent->children[index + 1];
    parent->key_count--;
    return left_index;
}

static void borrow_from_previous(TreeContext *tree, int parent_index, int child_index)
{
    TreeNode *parent = &tree->nodes[parent_index];
    int child_node_index = parent->children[child_index];
    int sibling_node_index = parent->children[child_index - 1];
    TreeNode *child = &tree->nodes[child_node_index];
    TreeNode *sibling = &tree->nodes[sibling_node_index];
    for (int index = child->key_count; index > 0; --index) child->keys[index] = child->keys[index - 1];
    if (!child->leaf) {
        for (int index = child->key_count + 1; index > 0; --index)
            child->children[index] = child->children[index - 1];
        child->children[0] = sibling->children[sibling->key_count];
    }
    child->keys[0] = parent->keys[child_index - 1];
    parent->keys[child_index - 1] = sibling->keys[sibling->key_count - 1];
    child->key_count++;
    sibling->key_count--;
}

static void borrow_from_next(TreeContext *tree, int parent_index, int child_index)
{
    TreeNode *parent = &tree->nodes[parent_index];
    int child_node_index = parent->children[child_index];
    int sibling_node_index = parent->children[child_index + 1];
    TreeNode *child = &tree->nodes[child_node_index];
    TreeNode *sibling = &tree->nodes[sibling_node_index];
    child->keys[child->key_count++] = parent->keys[child_index];
    if (!child->leaf) child->children[child->key_count] = sibling->children[0];
    parent->keys[child_index] = sibling->keys[0];
    for (int index = 0; index < sibling->key_count - 1; ++index)
        sibling->keys[index] = sibling->keys[index + 1];
    if (!sibling->leaf) {
        for (int index = 0; index < sibling->key_count; ++index)
            sibling->children[index] = sibling->children[index + 1];
    }
    sibling->key_count--;
}

static void remove_key_from_node(TreeContext *tree, int node_index, int64_t key)
{
    TreeNode *node = &tree->nodes[node_index];
    int key_index = find_key(node, key);
    if (key_index >= 0) {
        if (node->leaf) {
            for (int index = key_index; index < node->key_count - 1; ++index)
                node->keys[index] = node->keys[index + 1];
            node->key_count--;
            return;
        }
        int left_index = node->children[key_index];
        int right_index = node->children[key_index + 1];
        if (tree->nodes[left_index].key_count >= 2) {
            int64_t replacement = predecessor(tree, left_index);
            node->keys[key_index] = replacement;
            remove_key_from_node(tree, left_index, replacement);
        } else if (tree->nodes[right_index].key_count >= 2) {
            int64_t replacement = successor(tree, right_index);
            node->keys[key_index] = replacement;
            remove_key_from_node(tree, right_index, replacement);
        } else {
            int merged = merge_children(tree, node_index, key_index);
            remove_key_from_node(tree, merged, key);
        }
        return;
    }
    if (node->leaf) return;
    int child_index = 0;
    while (child_index < node->key_count && key > node->keys[child_index]) ++child_index;
    int child_node_index = node->children[child_index];
    if (tree->nodes[child_node_index].key_count == 1) {
        if (child_index > 0 && tree->nodes[node->children[child_index - 1]].key_count >= 2) {
            borrow_from_previous(tree, node_index, child_index);
        } else if (child_index < node->key_count &&
                   tree->nodes[node->children[child_index + 1]].key_count >= 2) {
            borrow_from_next(tree, node_index, child_index);
        } else if (child_index < node->key_count) {
            child_node_index = merge_children(tree, node_index, child_index);
        } else {
            child_node_index = merge_children(tree, node_index, child_index - 1);
        }
    }
    remove_key_from_node(tree, child_node_index, key);
}

static void remove_key(TreeContext *tree, int64_t key, int64_t *result)
{
    if (!contains(tree, tree->root, key)) {
        *result = 0;
        return;
    }
    remove_key_from_node(tree, tree->root, key);
    *result = 1;
    if (tree->root >= 0 && tree->nodes[tree->root].key_count == 0) {
        int old_root = tree->root;
        tree->root = tree->nodes[old_root].leaf ? -1 : tree->nodes[old_root].children[0];
    }
}

static void traverse(TreeContext *tree, int node_index)
{
    if (node_index < 0) return;
    TreeNode *node = &tree->nodes[node_index];
    for (int index = 0; index < node->key_count; ++index) {
        if (!node->leaf) traverse(tree, node->children[index]);
        tree->final_keys[tree->final_count++] = node->keys[index];
    }
    if (!node->leaf) traverse(tree, node->children[node->key_count]);
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned int byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

extern "C" int64_t tree_234(const int64_t *input, size_t input_length, uint8_t *output, size_t capacity)
{
    if (input == NULL || input_length < 1u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    size_t operation_count = (size_t)input[0];
    if (input_length != 1u + 2u * operation_count) return -1;
    for (size_t operation = 0; operation < operation_count; ++operation)
        if (input[1u + operation * 2u] != 0 && input[1u + operation * 2u] != 1) return -1;

    TreeContext tree = {0};
    tree.root = -1;
    int64_t remove_results[MAX_OPERATIONS] = {0};
    size_t remove_count = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        int64_t code = input[1u + operation * 2u];
        int64_t key = input[2u + operation * 2u];
        if (code == 0) {
            insert_key(&tree, key);
        } else {
            remove_key(&tree, key, &remove_results[remove_count++]);
        }
    }
    traverse(&tree, tree.root);

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = (int64_t)remove_count;
    for (size_t index = 0; index < remove_count; ++index) words[1u + index] = remove_results[index];
    words[1u + remove_count] = (int64_t)tree.final_count;
    for (size_t index = 0; index < tree.final_count; ++index)
        words[2u + remove_count + index] = tree.final_keys[index];
    size_t word_count = 2u + remove_count + tree.final_count;
    size_t output_bytes = word_count * 8u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < word_count; ++index)
        write_i64_le(output, index * 8u, words[index]);
    return (int64_t)output_bytes;
}
