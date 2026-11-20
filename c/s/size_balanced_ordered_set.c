#include <stddef.h>
#include <stdint.h>

#define SBT_MAX_OPERATIONS 128
#define SBT_MAX_NODES 128
#define SBT_MISSING INT64_C(-1025)

typedef struct {
    int64_t key[SBT_MAX_NODES + 1];
    int size[SBT_MAX_NODES + 1];
    int left[SBT_MAX_NODES + 1];
    int right[SBT_MAX_NODES + 1];
    int used;
} SbtTree;

static int sbt_size(const SbtTree *tree, int node) {
    return node == 0 ? 0 : tree->size[node];
}

static void sbt_update_size(SbtTree *tree, int node) {
    tree->size[node] = sbt_size(tree, tree->left[node])
                     + sbt_size(tree, tree->right[node]) + 1;
}

static int sbt_rotate_left(SbtTree *tree, int root) {
    const int pivot = tree->right[root];
    tree->right[root] = tree->left[pivot];
    tree->left[pivot] = root;
    sbt_update_size(tree, root);
    sbt_update_size(tree, pivot);
    return pivot;
}

static int sbt_rotate_right(SbtTree *tree, int root) {
    const int pivot = tree->left[root];
    tree->left[root] = tree->right[pivot];
    tree->right[pivot] = root;
    sbt_update_size(tree, root);
    sbt_update_size(tree, pivot);
    return pivot;
}

static int sbt_maintain(SbtTree *tree, int root) {
    if (root == 0) return 0;

    const int left = tree->left[root];
    const int right = tree->right[root];
    if (sbt_size(tree, left) < sbt_size(tree, tree->left[right])) {
        tree->right[root] = sbt_rotate_right(tree, right);
        root = sbt_rotate_left(tree, root);
        tree->left[root] = sbt_maintain(tree, tree->left[root]);
        tree->right[root] = sbt_maintain(tree, tree->right[root]);
        return sbt_maintain(tree, root);
    }
    if (sbt_size(tree, left) < sbt_size(tree, tree->right[right])) {
        root = sbt_rotate_left(tree, root);
        tree->left[root] = sbt_maintain(tree, tree->left[root]);
        return sbt_maintain(tree, root);
    }
    if (sbt_size(tree, right) < sbt_size(tree, tree->left[left])) {
        root = sbt_rotate_right(tree, root);
        tree->right[root] = sbt_maintain(tree, tree->right[root]);
        return sbt_maintain(tree, root);
    }
    if (sbt_size(tree, right) < sbt_size(tree, tree->right[left])) {
        tree->left[root] = sbt_rotate_left(tree, left);
        root = sbt_rotate_right(tree, root);
        tree->left[root] = sbt_maintain(tree, tree->left[root]);
        tree->right[root] = sbt_maintain(tree, tree->right[root]);
        return sbt_maintain(tree, root);
    }
    return root;
}

static int sbt_contains(const SbtTree *tree, int root, int64_t key) {
    while (root != 0) {
        if (key < tree->key[root]) root = tree->left[root];
        else if (key > tree->key[root]) root = tree->right[root];
        else return 1;
    }
    return 0;
}

static int sbt_insert_new(SbtTree *tree, int root, int64_t key) {
    if (root == 0) {
        const int node = ++tree->used;
        tree->key[node] = key;
        tree->size[node] = 1;
        return node;
    }
    if (key < tree->key[root])
        tree->left[root] = sbt_insert_new(tree, tree->left[root], key);
    else
        tree->right[root] = sbt_insert_new(tree, tree->right[root], key);
    sbt_update_size(tree, root);
    return sbt_maintain(tree, root);
}

static int64_t sbt_rank_less(const SbtTree *tree, int root, int64_t key) {
    int64_t rank = 0;
    while (root != 0) {
        if (key <= tree->key[root]) root = tree->left[root];
        else {
            rank += sbt_size(tree, tree->left[root]) + 1;
            root = tree->right[root];
        }
    }
    return rank;
}

static int64_t sbt_kth(const SbtTree *tree, int root, int64_t index) {
    if (index < 0 || index >= sbt_size(tree, root)) return SBT_MISSING;
    while (root != 0) {
        const int left_size = sbt_size(tree, tree->left[root]);
        if (index == left_size) return tree->key[root];
        if (index < left_size) root = tree->left[root];
        else {
            index -= left_size + 1;
            root = tree->right[root];
        }
    }
    return SBT_MISSING;
}

static int64_t sbt_predecessor(const SbtTree *tree, int root, int64_t key) {
    int64_t answer = SBT_MISSING;
    while (root != 0) {
        if (tree->key[root] < key) {
            answer = tree->key[root];
            root = tree->right[root];
        } else root = tree->left[root];
    }
    return answer;
}

static int64_t sbt_successor(const SbtTree *tree, int root, int64_t key) {
    int64_t answer = SBT_MISSING;
    while (root != 0) {
        if (tree->key[root] > key) {
            answer = tree->key[root];
            root = tree->left[root];
        } else root = tree->right[root];
    }
    return answer;
}

int64_t size_balanced_ordered_set(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 1 + 2 * SBT_MAX_OPERATIONS) return -1;
    const int64_t operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > SBT_MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != 1 + 2 * operation_count) return -1;

    for (size_t i = 0; i < operation_count; ++i) {
        const int64_t operation = input[1 + 2 * i];
        const int64_t argument = input[2 + 2 * i];
        if (operation < 0 || operation > 4) return -1;
        if (operation == 2) {
            if (argument < 0 || argument > 127) return -1;
        } else if (argument < -1024 || argument > 1023) return -1;
    }

    SbtTree tree = {0};
    int root = 0;
    int64_t checksum = 0;
    for (size_t i = 0; i < operation_count; ++i) {
        const int64_t operation = input[1 + 2 * i];
        const int64_t argument = input[2 + 2 * i];
        int64_t answer;
        if (operation == 0) {
            if (!sbt_contains(&tree, root, argument))
                root = sbt_insert_new(&tree, root, argument);
            continue;
        }
        if (operation == 1) answer = sbt_rank_less(&tree, root, argument);
        else if (operation == 2) answer = sbt_kth(&tree, root, argument);
        else if (operation == 3) answer = sbt_predecessor(&tree, root, argument);
        else answer = sbt_successor(&tree, root, argument);
        checksum += (int64_t)(i + 1) * (answer + 1025);
    }
    return checksum;
}
