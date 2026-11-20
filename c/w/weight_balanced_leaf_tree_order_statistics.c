#include <stddef.h>
#include <stdint.h>

#define WBLT_MAX_OPERATIONS 64
#define WBLT_NODE_CAPACITY (2 * WBLT_MAX_OPERATIONS + 1)
#define WBLT_MISSING (-129)

typedef struct {
    int left[WBLT_NODE_CAPACITY];
    int right[WBLT_NODE_CAPACITY];
    int size[WBLT_NODE_CAPACITY];
    int free_next[WBLT_NODE_CAPACITY];
    int64_t key[WBLT_NODE_CAPACITY];
    int64_t maximum[WBLT_NODE_CAPACITY];
    int next_node;
    int free_head;
} WbltTree;

static int allocate_node(WbltTree *tree) {
    int node;
    if (tree->free_head != 0) {
        node = tree->free_head;
        tree->free_head = tree->free_next[node];
    } else {
        node = tree->next_node++;
    }
    tree->left[node] = 0;
    tree->right[node] = 0;
    tree->size[node] = 0;
    tree->free_next[node] = 0;
    tree->key[node] = 0;
    tree->maximum[node] = 0;
    return node;
}

static void release_node(WbltTree *tree, int node) {
    tree->left[node] = 0;
    tree->right[node] = 0;
    tree->size[node] = 0;
    tree->key[node] = 0;
    tree->maximum[node] = 0;
    tree->free_next[node] = tree->free_head;
    tree->free_head = node;
}

static int new_leaf(WbltTree *tree, int64_t value) {
    int node = allocate_node(tree);
    tree->key[node] = value;
    tree->maximum[node] = value;
    tree->size[node] = 1;
    return node;
}

static int join_nodes(WbltTree *tree, int left, int right) {
    int node = allocate_node(tree);
    tree->left[node] = left;
    tree->right[node] = right;
    tree->size[node] = tree->size[left] + tree->size[right];
    tree->maximum[node] = tree->maximum[right];
    return node;
}

static void cut_node(WbltTree *tree, int node, int *left, int *right) {
    *left = tree->left[node];
    *right = tree->right[node];
    release_node(tree, node);
}

static int too_heavy(int left_size, int right_size) {
    return left_size > 3 * right_size;
}

static int merge_nodes(WbltTree *tree, int left, int right);

static int rebalance_node(WbltTree *tree, int node) {
    if (tree->size[node] == 1) return node;
    int left = tree->left[node];
    int right = tree->right[node];
    if (too_heavy(tree->size[left], tree->size[right]) ||
        too_heavy(tree->size[right], tree->size[left])) {
        cut_node(tree, node, &left, &right);
        return merge_nodes(tree, left, right);
    }
    return node;
}

static int merge_nodes(WbltTree *tree, int left, int right) {
    if (left == 0) return right;
    if (right == 0) return left;
    if (too_heavy(tree->size[left], tree->size[right])) {
        int a, b;
        cut_node(tree, left, &a, &b);
        return rebalance_node(tree, join_nodes(tree, a, merge_nodes(tree, b, right)));
    }
    if (too_heavy(tree->size[right], tree->size[left])) {
        int a, b;
        cut_node(tree, right, &a, &b);
        return rebalance_node(tree, join_nodes(tree, merge_nodes(tree, left, a), b));
    }
    return join_nodes(tree, left, right);
}

static int insert_key(WbltTree *tree, int node, int64_t value) {
    if (node == 0) return new_leaf(tree, value);
    if (tree->size[node] == 1) {
        if (value <= tree->key[node]) return join_nodes(tree, new_leaf(tree, value), node);
        return join_nodes(tree, node, new_leaf(tree, value));
    }
    if (value <= tree->maximum[tree->left[node]]) {
        tree->left[node] = insert_key(tree, tree->left[node], value);
    } else {
        tree->right[node] = insert_key(tree, tree->right[node], value);
    }
    tree->size[node] = tree->size[tree->left[node]] + tree->size[tree->right[node]];
    tree->maximum[node] = tree->maximum[tree->right[node]];
    return rebalance_node(tree, node);
}

static int remove_key(WbltTree *tree, int node, int64_t value, int *removed) {
    *removed = 0;
    if (node == 0) return 0;
    if (tree->size[node] == 1) {
        if (tree->key[node] != value) return node;
        release_node(tree, node);
        *removed = 1;
        return 0;
    }
    if (value <= tree->maximum[tree->left[node]]) {
        tree->left[node] = remove_key(tree, tree->left[node], value, removed);
    } else {
        tree->right[node] = remove_key(tree, tree->right[node], value, removed);
    }
    if (!*removed) return node;
    if (tree->left[node] == 0 || tree->right[node] == 0) {
        int child = tree->left[node] != 0 ? tree->left[node] : tree->right[node];
        release_node(tree, node);
        return child;
    }
    tree->size[node] = tree->size[tree->left[node]] + tree->size[tree->right[node]];
    tree->maximum[node] = tree->maximum[tree->right[node]];
    return rebalance_node(tree, node);
}

static int64_t rank_less(const WbltTree *tree, int node, int64_t value) {
    if (node == 0) return 0;
    if (tree->size[node] == 1) return tree->key[node] < value;
    int left = tree->left[node];
    if (value <= tree->maximum[left]) return rank_less(tree, left, value);
    return tree->size[left] + rank_less(tree, tree->right[node], value);
}

static int64_t kth(const WbltTree *tree, int node, int64_t index) {
    if (node == 0 || index >= tree->size[node]) return WBLT_MISSING;
    while (tree->size[node] != 1) {
        int left = tree->left[node];
        if (index < tree->size[left]) node = left;
        else {
            index -= tree->size[left];
            node = tree->right[node];
        }
    }
    return tree->key[node];
}

static int64_t predecessor(const WbltTree *tree, int node, int64_t value) {
    if (node == 0) return WBLT_MISSING;
    if (tree->size[node] == 1) return tree->key[node] < value ? tree->key[node] : WBLT_MISSING;
    int left = tree->left[node];
    if (value <= tree->maximum[left]) return predecessor(tree, left, value);
    int64_t answer = predecessor(tree, tree->right[node], value);
    return answer == WBLT_MISSING ? tree->maximum[left] : answer;
}

static int64_t successor(const WbltTree *tree, int node, int64_t value) {
    if (node == 0) return WBLT_MISSING;
    if (tree->size[node] == 1) return tree->key[node] > value ? tree->key[node] : WBLT_MISSING;
    int left = tree->left[node];
    if (value < tree->maximum[left]) return successor(tree, left, value);
    return successor(tree, tree->right[node], value);
}

int64_t weight_balanced_leaf_tree_order_statistics(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 130) return -1;
    int64_t q = input[0];
    if (q < 0 || q > WBLT_MAX_OPERATIONS || length != (size_t)(1 + 2 * q)) return -1;
    for (int64_t i = 0; i < q; ++i) {
        int64_t operation = input[1 + 2 * i];
        int64_t argument = input[2 + 2 * i];
        if (operation < 0 || operation > 5) return -1;
        if (operation == 3) {
            if (argument < 0 || argument >= WBLT_MAX_OPERATIONS) return -1;
        } else if (argument < -128 || argument > 127) return -1;
    }
    WbltTree tree = {0};
    tree.next_node = 1;
    int root = 0;
    int64_t checksum = 0;
    for (int64_t i = 0; i < q; ++i) {
        int64_t operation = input[1 + 2 * i];
        int64_t argument = input[2 + 2 * i];
        if (operation == 0) root = insert_key(&tree, root, argument);
        else if (operation == 1) {
            int removed;
            root = remove_key(&tree, root, argument, &removed);
        } else {
            int64_t answer;
            if (operation == 2) answer = rank_less(&tree, root, argument);
            else if (operation == 3) answer = kth(&tree, root, argument);
            else if (operation == 4) answer = predecessor(&tree, root, argument);
            else answer = successor(&tree, root, argument);
            checksum += (i + 1) * (answer - WBLT_MISSING);
        }
    }
    return checksum;
}
