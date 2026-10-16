#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 128
#define INVALID_RESULT INT64_C(-1)
#define CAPACITY_RESULT INT64_C(-2)

typedef struct {
    int64_t key;
    size_t left;
    size_t right;
    bool red;
} Node;

static bool is_red(const Node *tree, size_t node) { return node != 0 && tree[node].red; }

static void flip_colors(Node *tree, size_t node) {
    tree[node].red = !tree[node].red;
    tree[tree[node].left].red = !tree[tree[node].left].red;
    tree[tree[node].right].red = !tree[tree[node].right].red;
}

static size_t rotate_left(Node *tree, size_t node) {
    const size_t pivot = tree[node].right;
    tree[node].right = tree[pivot].left;
    tree[pivot].left = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}

static size_t rotate_right(Node *tree, size_t node) {
    const size_t pivot = tree[node].left;
    tree[node].left = tree[pivot].right;
    tree[pivot].right = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}

static size_t insert_node(Node *tree, size_t node, int64_t key, size_t *next_node) {
    if (node == 0) {
        const size_t created = (*next_node)++;
        tree[created] = (Node){ .key = key, .red = true };
        return created;
    }
    if (is_red(tree, tree[node].left) && is_red(tree, tree[node].right)) flip_colors(tree, node);
    if (key == tree[node].key) tree[node].key = key;
    else if (key < tree[node].key) tree[node].left = insert_node(tree, tree[node].left, key, next_node);
    else tree[node].right = insert_node(tree, tree[node].right, key, next_node);
    if (is_red(tree, tree[node].right) && !is_red(tree, tree[node].left)) node = rotate_left(tree, node);
    if (is_red(tree, tree[node].left) && is_red(tree, tree[tree[node].left].left)) node = rotate_right(tree, node);
    return node;
}

static size_t find_node(const Node *tree, size_t node, int64_t key) {
    while (node != 0) {
        if (key < tree[node].key) node = tree[node].left;
        else if (key > tree[node].key) node = tree[node].right;
        else return node;
    }
    return 0;
}

static void insertion_sort(int64_t *values, size_t count) {
    for (size_t index = 1; index < count; ++index) {
        const int64_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t red_black_tree_insert_search(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1) return INVALID_RESULT;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_OPERATIONS || length != 1 + 2 * (size_t)count_value) return INVALID_RESULT;
    const size_t operation_count = (size_t)count_value;
    for (size_t op = 0; op < operation_count; ++op) {
        const int64_t opcode = input[1 + 2 * op], key = input[2 + 2 * op];
        if ((opcode != 0 && opcode != 1) || key < INT32_MIN || key > INT32_MAX) return INVALID_RESULT;
    }

    Node tree[MAX_OPERATIONS + 1] = {0};
    int64_t keys[MAX_OPERATIONS], search_results[MAX_OPERATIONS];
    size_t root = 0, next_node = 1, key_count = 0, search_count = 0;
    for (size_t op = 0; op < operation_count; ++op) {
        const int64_t opcode = input[1 + 2 * op], key = input[2 + 2 * op];
        if (opcode == 0) {
            if (find_node(tree, root, key) != 0) return INVALID_RESULT;
            root = insert_node(tree, root, key, &next_node);
            tree[root].red = false;
            keys[key_count++] = key;
        } else {
            search_results[search_count++] = find_node(tree, root, key) != 0 ? 1 : 0;
        }
    }
    insertion_sort(keys, key_count);
    const size_t required = (2 + key_count + search_count) * 8;
    if (output == NULL || capacity < required) return CAPACITY_RESULT;
    size_t offset = 0;
    write_i64_le(output, offset, (int64_t)key_count); offset += 8;
    for (size_t index = 0; index < key_count; ++index, offset += 8) write_i64_le(output, offset, keys[index]);
    write_i64_le(output, offset, (int64_t)search_count); offset += 8;
    for (size_t index = 0; index < search_count; ++index, offset += 8) write_i64_le(output, offset, search_results[index]);
    return (int64_t)required;
}
