/* Fixed-capacity B-tree multiset with split-on-descent insertion. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 257
#define MAX_NODE_KEYS 15
#define MAX_NODE_CHILDREN 16
#define MAX_KEY_COUNT 256
#define MAX_OPERATIONS 511
#define OFFSET INT64_C(1000000)
#define HASH_MOD INT64_C(1000000007)

typedef struct {
    int64_t keys[MAX_NODE_COUNT][MAX_NODE_KEYS];
    size_t children[MAX_NODE_COUNT][MAX_NODE_CHILDREN];
    uint8_t key_count[MAX_NODE_COUNT];
    bool leaf[MAX_NODE_COUNT];
    size_t used_nodes;
    size_t root;
    size_t min_degree;
} BTree;

static bool split_child(BTree *tree, size_t parent, size_t child_index)
{
    if (tree->used_nodes >= MAX_NODE_COUNT) return false;
    const size_t child = tree->children[parent][child_index];
    const size_t degree = tree->min_degree;
    const size_t sibling = tree->used_nodes++;
    tree->leaf[sibling] = tree->leaf[child];
    tree->key_count[sibling] = (uint8_t)(degree - 1);
    for (size_t i = 0; i < degree - 1; ++i)
        tree->keys[sibling][i] = tree->keys[child][degree + i];
    if (!tree->leaf[child])
        for (size_t i = 0; i < degree; ++i)
            tree->children[sibling][i] = tree->children[child][degree + i];

    const size_t parent_count = tree->key_count[parent];
    for (size_t i = parent_count + 1; i > child_index + 1; --i)
        tree->children[parent][i] = tree->children[parent][i - 1];
    tree->children[parent][child_index + 1] = sibling;
    for (size_t i = parent_count; i > child_index; --i)
        tree->keys[parent][i] = tree->keys[parent][i - 1];
    tree->keys[parent][child_index] = tree->keys[child][degree - 1];
    tree->key_count[child] = (uint8_t)(degree - 1);
    tree->key_count[parent] = (uint8_t)(parent_count + 1);
    return true;
}

static bool insert_non_full(BTree *tree, size_t node, int64_t key)
{
    size_t index = tree->key_count[node];
    if (tree->leaf[node]) {
        while (index > 0 && key <= tree->keys[node][index - 1]) {
            tree->keys[node][index] = tree->keys[node][index - 1];
            --index;
        }
        tree->keys[node][index] = key;
        ++tree->key_count[node];
        return true;
    }
    while (index > 0 && key <= tree->keys[node][index - 1]) --index;
    const size_t child = tree->children[node][index];
    if (tree->key_count[child] == 2 * tree->min_degree - 1) {
        if (!split_child(tree, node, index)) return false;
        if (tree->keys[node][index] < key) ++index;
    }
    return insert_non_full(tree, tree->children[node][index], key);
}

static bool insert_key(BTree *tree, int64_t key)
{
    if (tree->key_count[tree->root] == 2 * tree->min_degree - 1) {
        if (tree->used_nodes + 2 > MAX_NODE_COUNT) return false;
        const size_t old_root = tree->root;
        const size_t new_root = tree->used_nodes++;
        tree->leaf[new_root] = false;
        tree->key_count[new_root] = 0;
        tree->children[new_root][0] = old_root;
        tree->root = new_root;
        if (!split_child(tree, new_root, 0)) return false;
    }
    return insert_non_full(tree, tree->root, key);
}

static bool search_key(const BTree *tree, int64_t key)
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

static int64_t walk_in_order(const BTree *tree, size_t operation_count, int64_t *ordered_sum)
{
    size_t node_stack[32], position_stack[32], depth = 1, index = 0;
    int64_t hash = 0;
    node_stack[0] = tree->root;
    position_stack[0] = 0;
    while (depth > 0) {
        const size_t top = depth - 1;
        const size_t node = node_stack[top];
        const size_t count = tree->key_count[node];
        if (tree->leaf[node]) {
            if (position_stack[top] == count) { --depth; continue; }
            const int64_t value = tree->keys[node][position_stack[top]++];
            hash = (hash * 257 + value + INT64_C(1000001)) % HASH_MOD;
            if (ordered_sum != NULL)
                *ordered_sum += (int64_t)(operation_count + index + 1) * (value + OFFSET);
            ++index;
        } else if (position_stack[top] > 2 * count) {
            --depth;
        } else {
            const size_t position = position_stack[top]++;
            if (position % 2 == 0) {
                node_stack[depth] = tree->children[node][position / 2];
                position_stack[depth] = 0;
                ++depth;
            } else {
                const int64_t value = tree->keys[node][position / 2];
                hash = (hash * 257 + value + INT64_C(1000001)) % HASH_MOD;
                if (ordered_sum != NULL)
                    *ordered_sum += (int64_t)(operation_count + index + 1) * (value + OFFSET);
                ++index;
            }
        }
    }
    return hash;
}

int64_t b_tree_benchmark(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 1024) return -1;
    if (values[0] < 2 || values[0] > 8 || values[1] < 0 || values[1] > MAX_OPERATIONS)
        return -1;
    const size_t operation_count = (size_t)values[1];
    if (length != 2 + 2 * operation_count) return -1;

    BTree tree = {0};
    tree.used_nodes = 1;
    tree.root = 0;
    tree.min_degree = (size_t)values[0];
    tree.leaf[tree.root] = true;
    size_t key_count = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[2 + 2 * operation];
        const int64_t payload = values[3 + 2 * operation];
        int64_t observed = 0;
        if (opcode == 0) {
            if (payload < -OFFSET || payload > OFFSET || key_count == MAX_KEY_COUNT) return -1;
            if (!insert_key(&tree, payload)) return -1;
            ++key_count;
            observed = 1;
        } else if (opcode == 1) {
            if (payload < -OFFSET || payload > OFFSET) return -1;
            observed = search_key(&tree, payload) ? 1 : 0;
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = walk_in_order(&tree, 0, NULL);
        } else return -1;
        checksum += (int64_t)(operation + 1) * (observed + OFFSET);
    }
    walk_in_order(&tree, operation_count, &checksum);
    return checksum;
}
