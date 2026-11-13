#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 32
#define MAX_OPERATIONS 32
#define MAX_KEY 1000
#define MAX_NODES 64

typedef struct {
    int64_t key[MAX_NODES + 1];
    int height[MAX_NODES + 1];
    int size[MAX_NODES + 1];
    int left[MAX_NODES + 1];
    int right[MAX_NODES + 1];
    int used;
} AvlTree;

static int node_height(const AvlTree *tree, int node) { return node == 0 ? 0 : tree->height[node]; }
static int node_size(const AvlTree *tree, int node) { return node == 0 ? 0 : tree->size[node]; }

static void refresh(AvlTree *tree, int node) {
    const int lh = node_height(tree, tree->left[node]);
    const int rh = node_height(tree, tree->right[node]);
    tree->height[node] = (lh > rh ? lh : rh) + 1;
    tree->size[node] = node_size(tree, tree->left[node]) + node_size(tree, tree->right[node]) + 1;
}

static int rotate_right(AvlTree *tree, int root) {
    const int pivot = tree->left[root];
    tree->left[root] = tree->right[pivot];
    tree->right[pivot] = root;
    refresh(tree, root);
    refresh(tree, pivot);
    return pivot;
}

static int rotate_left(AvlTree *tree, int root) {
    const int pivot = tree->right[root];
    tree->right[root] = tree->left[pivot];
    tree->left[pivot] = root;
    refresh(tree, root);
    refresh(tree, pivot);
    return pivot;
}

static int rebalance(AvlTree *tree, int root) {
    refresh(tree, root);
    const int difference = node_height(tree, tree->left[root]) - node_height(tree, tree->right[root]);
    if (difference > 1) {
        const int child = tree->left[root];
        if (node_height(tree, tree->left[child]) < node_height(tree, tree->right[child]))
            tree->left[root] = rotate_left(tree, child);
        return rotate_right(tree, root);
    }
    if (difference < -1) {
        const int child = tree->right[root];
        if (node_height(tree, tree->right[child]) < node_height(tree, tree->left[child]))
            tree->right[root] = rotate_right(tree, child);
        return rotate_left(tree, root);
    }
    return root;
}

static int insert_key(AvlTree *tree, int root, int64_t key) {
    if (root == 0) {
        const int node = ++tree->used;
        tree->key[node] = key;
        tree->height[node] = tree->size[node] = 1;
        return node;
    }
    if (key < tree->key[root]) tree->left[root] = insert_key(tree, tree->left[root], key);
    else if (key > tree->key[root]) tree->right[root] = insert_key(tree, tree->right[root], key);
    else return root;
    return rebalance(tree, root);
}

static int minimum_node(const AvlTree *tree, int root) {
    while (tree->left[root] != 0) root = tree->left[root];
    return root;
}

static int erase_key(AvlTree *tree, int root, int64_t key) {
    if (root == 0) return 0;
    if (key < tree->key[root]) tree->left[root] = erase_key(tree, tree->left[root], key);
    else if (key > tree->key[root]) tree->right[root] = erase_key(tree, tree->right[root], key);
    else if (tree->left[root] == 0) return tree->right[root];
    else if (tree->right[root] == 0) return tree->left[root];
    else {
        const int successor = minimum_node(tree, tree->right[root]);
        tree->key[root] = tree->key[successor];
        tree->right[root] = erase_key(tree, tree->right[root], tree->key[successor]);
    }
    return rebalance(tree, root);
}

static int64_t kth(const AvlTree *tree, int root, int64_t rank) {
    if (rank < 1 || rank > node_size(tree, root)) return -1;
    while (root != 0) {
        const int left_count = node_size(tree, tree->left[root]);
        if (rank == left_count + 1) return tree->key[root];
        if (rank <= left_count) root = tree->left[root];
        else { rank -= left_count + 1; root = tree->right[root]; }
    }
    return -1;
}

static int64_t count_le(const AvlTree *tree, int root, int64_t key) {
    int64_t count = 0;
    while (root != 0) {
        if (tree->key[root] <= key) {
            count += node_size(tree, tree->left[root]) + 1;
            root = tree->right[root];
        } else root = tree->left[root];
    }
    return count;
}

static int64_t predecessor(const AvlTree *tree, int root, int64_t key) {
    int64_t answer = -1;
    while (root != 0) {
        if (tree->key[root] <= key) { answer = tree->key[root]; root = tree->right[root]; }
        else root = tree->left[root];
    }
    return answer;
}

static int64_t successor(const AvlTree *tree, int root, int64_t key) {
    int64_t answer = -1;
    while (root != 0) {
        if (tree->key[root] >= key) { answer = tree->key[root]; root = tree->left[root]; }
        else root = tree->right[root];
    }
    return answer;
}

int64_t ordered_set_avl_order_statistics(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 99) return -1;
    const int64_t initial_count = input[0], operation_count = input[1];
    if (initial_count < 0 || initial_count > MAX_ITEMS || operation_count < 0 || operation_count > MAX_OPERATIONS)
        return -1;
    if (length != (size_t)(2 + initial_count + 2 * operation_count)) return -1;
    for (int64_t i = 0; i < initial_count; ++i) {
        const int64_t key = input[2 + i];
        if (key < 0 || key > MAX_KEY || (i > 0 && input[1 + i] >= key)) return -1;
    }
    for (int64_t i = 0; i < operation_count; ++i) {
        const int64_t opcode = input[2 + initial_count + 2 * i];
        const int64_t key = input[3 + initial_count + 2 * i];
        if (opcode < 0 || opcode > 5 || key < 0 || key > MAX_KEY || (opcode == 2 && key < 1)) return -1;
    }

    AvlTree tree = {0};
    int root = 0;
    for (int64_t i = 0; i < initial_count; ++i) root = insert_key(&tree, root, input[2 + i]);
    int64_t checksum = 0, query_index = 0;
    for (int64_t i = 0; i < operation_count; ++i) {
        const int64_t opcode = input[2 + initial_count + 2 * i];
        const int64_t key = input[3 + initial_count + 2 * i];
        if (opcode == 0) root = insert_key(&tree, root, key);
        else if (opcode == 1) root = erase_key(&tree, root, key);
        else {
            int64_t answer;
            if (opcode == 2) answer = kth(&tree, root, key);
            else if (opcode == 3) answer = count_le(&tree, root, key);
            else if (opcode == 4) answer = predecessor(&tree, root, key);
            else answer = successor(&tree, root, key);
            ++query_index;
            checksum += query_index * (answer + 1);
        }
    }
    return checksum;
}
