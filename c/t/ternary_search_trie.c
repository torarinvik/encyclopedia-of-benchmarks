#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 64, MAX_KEY_LENGTH = 6, RECORD_WIDTH = 9,
       MAX_INPUT_VALUES = 577, MAX_PARSEABLE_INPUT_VALUES = 578,
       MAX_NODES = 384 };

typedef struct {
    int character;
    int left;
    int middle;
    int right;
    int64_t value;
    int present;
} tst_node;

static int put_node(tst_node *nodes, int node_id, const int64_t *key, int length,
                    int depth, int64_t value, int *old_value, int *size,
                    int *node_count) {
    if (node_id == 0) {
        node_id = ++(*node_count);
        nodes[node_id].character = (int)key[depth];
    }
    tst_node *node = &nodes[node_id];
    if (key[depth] < node->character) {
        node->left = put_node(nodes, node->left, key, length, depth, value,
                              old_value, size, node_count);
    } else if (key[depth] > node->character) {
        node->right = put_node(nodes, node->right, key, length, depth, value,
                               old_value, size, node_count);
    } else if (depth + 1 < length) {
        node->middle = put_node(nodes, node->middle, key, length, depth + 1,
                                value, old_value, size, node_count);
    } else {
        *old_value = node->present ? node->value : 0;
        if (!node->present) ++(*size);
        node->value = value;
        node->present = 1;
    }
    return node_id;
}

static int find_node(const tst_node *nodes, int node_id, const int64_t *key,
                     int length) {
    int depth = 0;
    while (node_id != 0) {
        const tst_node *node = &nodes[node_id];
        if (key[depth] < node->character) node_id = node->left;
        else if (key[depth] > node->character) node_id = node->right;
        else if (depth + 1 == length) return node_id;
        else { node_id = node->middle; ++depth; }
    }
    return 0;
}

static int delete_node(tst_node *nodes, int node_id, const int64_t *key,
                       int length, int depth, int64_t *removed, int *size) {
    if (node_id == 0) return 0;
    tst_node *node = &nodes[node_id];
    if (key[depth] < node->character) {
        node->left = delete_node(nodes, node->left, key, length, depth,
                                 removed, size);
    } else if (key[depth] > node->character) {
        node->right = delete_node(nodes, node->right, key, length, depth,
                                  removed, size);
    } else if (depth + 1 < length) {
        node->middle = delete_node(nodes, node->middle, key, length, depth + 1,
                                   removed, size);
    } else if (node->present) {
        *removed = node->value;
        node->value = 0;
        node->present = 0;
        --(*size);
    }
    if (!node->present && node->left == 0 && node->middle == 0 && node->right == 0)
        return 0;
    return node_id;
}

static int count_nodes(const tst_node *nodes, int node_id) {
    if (node_id == 0) return 0;
    const tst_node *node = &nodes[node_id];
    return node->present + count_nodes(nodes, node->left) +
           count_nodes(nodes, node->middle) + count_nodes(nodes, node->right);
}

static int count_matches(const tst_node *nodes, int node_id,
                         const int64_t *pattern, int length, int depth) {
    if (node_id == 0) return 0;
    const tst_node *node = &nodes[node_id];
    int token = (int)pattern[depth];
    if (token == '.') {
        int here = depth + 1 == length ? node->present :
                   count_matches(nodes, node->middle, pattern, length, depth + 1);
        return count_matches(nodes, node->left, pattern, length, depth) +
               here + count_matches(nodes, node->right, pattern, length, depth);
    }
    if (token < node->character)
        return count_matches(nodes, node->left, pattern, length, depth);
    if (token > node->character)
        return count_matches(nodes, node->right, pattern, length, depth);
    if (depth + 1 == length) return node->present;
    return count_matches(nodes, node->middle, pattern, length, depth + 1);
}

static int valid_input(const int64_t *input, size_t length, int *operation_count) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_VALUES) return 0;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return 0;
    *operation_count = (int)input[0];
    if (length != 1 + (size_t)(*operation_count) * RECORD_WIDTH) return 0;
    for (int operation = 0; operation < *operation_count; ++operation) {
        size_t base = 1 + (size_t)operation * RECORD_WIDTH;
        int64_t opcode = input[base];
        int64_t key_length = input[base + 1];
        if (opcode < 0 || opcode > 6 || key_length < 0 ||
            key_length > MAX_KEY_LENGTH) return 0;
        if ((opcode <= 2 && key_length == 0) ||
            (opcode == 6 && key_length != 0)) return 0;
        for (int index = 0; index < MAX_KEY_LENGTH; ++index) {
            int64_t character = input[base + 2 + (size_t)index];
            if (index < key_length) {
                if ((character < 'a' || character > 'z') &&
                    !(opcode == 5 && character == '.')) return 0;
            } else if (character != 0) return 0;
        }
        int64_t value = input[base + RECORD_WIDTH - 1];
        if (opcode == 0) {
            if (value < 1 || value > 65535) return 0;
        } else if (value != 0) return 0;
    }
    return 1;
}

int64_t ternary_search_trie(const int64_t *input, size_t length) {
    int operation_count = 0;
    if (!valid_input(input, length, &operation_count)) return -1;
    tst_node nodes[MAX_NODES + 1] = {{0}};
    int node_count = 0;
    int root = 0;
    int size = 0;
    int64_t total = 0;

    for (int operation = 0; operation < operation_count; ++operation) {
        size_t base = 1 + (size_t)operation * RECORD_WIDTH;
        int opcode = (int)input[base];
        int key_length = (int)input[base + 1];
        const int64_t *key = input + base + 2;
        int64_t value = input[base + RECORD_WIDTH - 1];
        int64_t observed = 0;

        if (opcode == 0) {
            root = put_node(nodes, root, key, key_length, 0, value, &observed,
                            &size, &node_count);
        } else if (opcode == 1) {
            int found = find_node(nodes, root, key, key_length);
            if (found != 0 && nodes[found].present) observed = nodes[found].value;
        } else if (opcode == 2) {
            root = delete_node(nodes, root, key, key_length, 0, &observed, &size);
        } else if (opcode == 3) {
            int node_id = root;
            int depth = 0;
            while (node_id != 0 && depth < key_length) {
                const tst_node *node = &nodes[node_id];
                if (key[depth] < node->character) node_id = node->left;
                else if (key[depth] > node->character) node_id = node->right;
                else {
                    ++depth;
                    if (node->present) observed = depth;
                    node_id = node->middle;
                }
            }
        } else if (opcode == 4) {
            if (key_length == 0) observed = size;
            else {
                int found = find_node(nodes, root, key, key_length);
                if (found != 0)
                    observed = nodes[found].present +
                               count_nodes(nodes, nodes[found].middle);
            }
        } else if (opcode == 5 && key_length != 0) {
            observed = count_matches(nodes, root, key, key_length, 0);
        } else if (opcode == 6) {
            observed = size;
        }
        total += (int64_t)(operation + 1) * observed;
    }
    return total;
}
