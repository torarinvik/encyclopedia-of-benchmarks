#include <stddef.h>
#include <stdint.h>

#define AA_MAX_OPERATIONS 256

typedef struct {
    int32_t key;
    int32_t left;
    int32_t right;
    int32_t level;
} aa_node;

typedef struct {
    aa_node nodes[AA_MAX_OPERATIONS];
    int32_t used;
} aa_tree;

static int32_t node_level(const aa_tree *tree, int32_t node) {
    return node < 0 ? 0 : tree->nodes[node].level;
}

static int32_t skew(aa_tree *tree, int32_t root) {
    if (root < 0) return root;
    int32_t left = tree->nodes[root].left;
    if (left < 0 || tree->nodes[left].level != tree->nodes[root].level) return root;
    tree->nodes[root].left = tree->nodes[left].right;
    tree->nodes[left].right = root;
    return left;
}

static int32_t split(aa_tree *tree, int32_t root) {
    if (root < 0) return root;
    int32_t right = tree->nodes[root].right;
    if (right < 0) return root;
    int32_t right_right = tree->nodes[right].right;
    if (right_right < 0 || tree->nodes[root].level != tree->nodes[right_right].level) return root;
    tree->nodes[root].right = tree->nodes[right].left;
    tree->nodes[right].left = root;
    tree->nodes[right].level++;
    return right;
}

static int32_t contains(const aa_tree *tree, int32_t root, int32_t key) {
    while (root >= 0) {
        if (key < tree->nodes[root].key) root = tree->nodes[root].left;
        else if (key > tree->nodes[root].key) root = tree->nodes[root].right;
        else return 1;
    }
    return 0;
}

static int32_t insert_node(aa_tree *tree, int32_t root, int32_t key) {
    if (root < 0) {
        int32_t fresh = tree->used++;
        tree->nodes[fresh].key = key;
        tree->nodes[fresh].left = -1;
        tree->nodes[fresh].right = -1;
        tree->nodes[fresh].level = 1;
        return fresh;
    }
    if (key < tree->nodes[root].key) tree->nodes[root].left = insert_node(tree, tree->nodes[root].left, key);
    else tree->nodes[root].right = insert_node(tree, tree->nodes[root].right, key);
    return split(tree, skew(tree, root));
}

static int32_t minimum_node(const aa_tree *tree, int32_t root) {
    while (tree->nodes[root].left >= 0) root = tree->nodes[root].left;
    return root;
}

static int32_t maximum_node(const aa_tree *tree, int32_t root) {
    while (tree->nodes[root].right >= 0) root = tree->nodes[root].right;
    return root;
}

static int32_t decrease_level(aa_tree *tree, int32_t root) {
    int32_t left_level = node_level(tree, tree->nodes[root].left);
    int32_t right_level = node_level(tree, tree->nodes[root].right);
    int32_t new_level = (left_level < right_level ? left_level : right_level) + 1;
    if (new_level < tree->nodes[root].level) {
        tree->nodes[root].level = new_level;
        int32_t right = tree->nodes[root].right;
        if (right >= 0 && new_level < tree->nodes[right].level) tree->nodes[right].level = new_level;
    }
    return root;
}

static int32_t remove_node(aa_tree *tree, int32_t root, int32_t key) {
    if (key < tree->nodes[root].key) {
        tree->nodes[root].left = remove_node(tree, tree->nodes[root].left, key);
    } else if (key > tree->nodes[root].key) {
        tree->nodes[root].right = remove_node(tree, tree->nodes[root].right, key);
    } else if (tree->nodes[root].left < 0 && tree->nodes[root].right < 0) {
        return -1;
    } else if (tree->nodes[root].left < 0) {
        int32_t successor = minimum_node(tree, tree->nodes[root].right);
        tree->nodes[root].key = tree->nodes[successor].key;
        tree->nodes[root].right = remove_node(tree, tree->nodes[root].right, tree->nodes[successor].key);
    } else {
        int32_t predecessor = maximum_node(tree, tree->nodes[root].left);
        tree->nodes[root].key = tree->nodes[predecessor].key;
        tree->nodes[root].left = remove_node(tree, tree->nodes[root].left, tree->nodes[predecessor].key);
    }
    root = skew(tree, decrease_level(tree, root));
    int32_t right = tree->nodes[root].right;
    if (right >= 0) {
        right = skew(tree, right);
        int32_t right_right = tree->nodes[right].right;
        if (right_right >= 0) tree->nodes[right].right = skew(tree, right_right);
        tree->nodes[root].right = right;
    }
    root = split(tree, root);
    right = tree->nodes[root].right;
    if (right >= 0) tree->nodes[root].right = split(tree, right);
    return root;
}

static void write_i32(uint8_t *output, size_t offset, int32_t value) {
    uint32_t bits = (uint32_t)value;
    output[offset] = (uint8_t)bits;
    output[offset + 1] = (uint8_t)(bits >> 8);
    output[offset + 2] = (uint8_t)(bits >> 16);
    output[offset + 3] = (uint8_t)(bits >> 24);
}

extern "C" int64_t aatree(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > AA_MAX_OPERATIONS) return -1;
    size_t operation_count = (size_t)input[0];
    if (length != 1 + 2 * operation_count) return -1;
    size_t output_bytes = 4 * operation_count;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;

    aa_tree tree = {0};
    int32_t root = -1;
    int32_t size = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        int64_t opcode = input[1 + 2 * operation];
        int64_t raw_key = input[2 + 2 * operation];
        if (opcode < 0 || opcode > 4) return -1;
        if (opcode <= 2 && (raw_key < INT32_MIN || raw_key > INT32_MAX)) return -1;
        if (opcode >= 3 && raw_key != 0) return -1;
        int32_t key = (int32_t)raw_key;
        int32_t result;
        if (opcode == 0) {
            if (contains(&tree, root, key)) return -1;
            root = insert_node(&tree, root, key);
            result = ++size;
        } else if (opcode == 1) {
            if (!contains(&tree, root, key)) return -1;
            root = remove_node(&tree, root, key);
            result = --size;
        } else if (opcode == 2) {
            result = contains(&tree, root, key);
        } else if (root < 0) {
            return -1;
        } else if (opcode == 3) {
            result = tree.nodes[minimum_node(&tree, root)].key;
        } else {
            result = tree.nodes[maximum_node(&tree, root)].key;
        }
        write_i32(output, 4 * operation, result);
    }
    return (int64_t)output_bytes;
}
