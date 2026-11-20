#include <stddef.h>
#include <stdint.h>

enum { DIET_MAX_Q = 32, DIET_ARENA = 64, DIET_MIN_KEY = -15, DIET_MAX_KEY = 15,
       DIET_MAX_PARSEABLE = 2 + 2 * DIET_MAX_Q };

typedef struct {
    int64_t lo;
    int64_t hi;
    int left;
    int right;
} DietNode;

static int diet_new(DietNode nodes[DIET_ARENA], int *used, int64_t lo, int64_t hi,
                    int left, int right) {
    int index = *used;
    if (index >= DIET_ARENA) return -1;
    nodes[index] = (DietNode){lo, hi, left, right};
    *used = index + 1;
    return index;
}

static int diet_pop_max(DietNode nodes[DIET_ARENA], int root,
                        int64_t *lo, int64_t *hi) {
    if (nodes[root].right < 0) {
        *lo = nodes[root].lo;
        *hi = nodes[root].hi;
        return nodes[root].left;
    }
    nodes[root].right = diet_pop_max(nodes, nodes[root].right, lo, hi);
    return root;
}

static int diet_pop_min(DietNode nodes[DIET_ARENA], int root,
                        int64_t *lo, int64_t *hi) {
    if (nodes[root].left < 0) {
        *lo = nodes[root].lo;
        *hi = nodes[root].hi;
        return nodes[root].right;
    }
    nodes[root].left = diet_pop_min(nodes, nodes[root].left, lo, hi);
    return root;
}

static void diet_max_interval(const DietNode nodes[DIET_ARENA], int root,
                              int64_t *lo, int64_t *hi) {
    while (nodes[root].right >= 0) root = nodes[root].right;
    *lo = nodes[root].lo;
    *hi = nodes[root].hi;
}

static void diet_min_interval(const DietNode nodes[DIET_ARENA], int root,
                              int64_t *lo, int64_t *hi) {
    while (nodes[root].left >= 0) root = nodes[root].left;
    *lo = nodes[root].lo;
    *hi = nodes[root].hi;
}

static int diet_insert(DietNode nodes[DIET_ARENA], int *used, int root,
                       int64_t key, int *interval_count, int *changed) {
    if (root < 0) {
        *changed = 1;
        ++*interval_count;
        return diet_new(nodes, used, key, key, -1, -1);
    }
    DietNode *node = &nodes[root];
    if (key < node->lo) {
        if (key + 1 == node->lo) {
            node->lo = key;
            *changed = 1;
            if (node->left >= 0) {
                int64_t pred_lo, pred_hi;
                diet_max_interval(nodes, node->left, &pred_lo, &pred_hi);
                if (pred_hi + 1 == key) {
                    node->left = diet_pop_max(nodes, node->left, &pred_lo, &pred_hi);
                    node->lo = pred_lo;
                    --*interval_count;
                }
            }
        } else {
            node->left = diet_insert(nodes, used, node->left, key,
                                     interval_count, changed);
        }
        return root;
    }
    if (key > node->hi) {
        if (key == node->hi + 1) {
            node->hi = key;
            *changed = 1;
            if (node->right >= 0) {
                int64_t succ_lo, succ_hi;
                diet_min_interval(nodes, node->right, &succ_lo, &succ_hi);
                if (key + 1 == succ_lo) {
                    node->right = diet_pop_min(nodes, node->right, &succ_lo, &succ_hi);
                    node->hi = succ_hi;
                    --*interval_count;
                }
            }
        } else {
            node->right = diet_insert(nodes, used, node->right, key,
                                      interval_count, changed);
        }
        return root;
    }
    *changed = 0;
    return root;
}

static int diet_delete(DietNode nodes[DIET_ARENA], int *used, int root,
                       int64_t key, int *interval_count, int *changed) {
    if (root < 0) {
        *changed = 0;
        return root;
    }
    DietNode *node = &nodes[root];
    if (key < node->lo) {
        node->left = diet_delete(nodes, used, node->left, key, interval_count, changed);
        return root;
    }
    if (key > node->hi) {
        node->right = diet_delete(nodes, used, node->right, key, interval_count, changed);
        return root;
    }
    *changed = 1;
    if (node->lo == node->hi) {
        --*interval_count;
        if (node->left < 0) return node->right;
        if (node->right < 0) return node->left;
        int64_t pred_lo, pred_hi;
        node->left = diet_pop_max(nodes, node->left, &pred_lo, &pred_hi);
        node->lo = pred_lo;
        node->hi = pred_hi;
        return root;
    }
    if (key == node->lo) {
        ++node->lo;
        return root;
    }
    if (key == node->hi) {
        --node->hi;
        return root;
    }
    int right_piece = diet_new(nodes, used, key + 1, node->hi, -1, node->right);
    node = &nodes[root];
    node->hi = key - 1;
    node->right = right_piece;
    ++*interval_count;
    return root;
}

static int diet_contains(const DietNode nodes[DIET_ARENA], int root, int64_t key) {
    while (root >= 0) {
        if (key < nodes[root].lo) root = nodes[root].left;
        else if (key > nodes[root].hi) root = nodes[root].right;
        else return 1;
    }
    return 0;
}

static int diet_valid(const int64_t *input, size_t length, int *q_out) {
    if (input == NULL || length < 1 || length > DIET_MAX_PARSEABLE) return 0;
    if (input[0] < 0 || input[0] > DIET_MAX_Q) return 0;
    int q = (int)input[0];
    if (length != 1 + 2 * (size_t)q) return 0;
    for (int i = 0; i < q; ++i) {
        int64_t opcode = input[1 + 2 * (size_t)i];
        int64_t key = input[2 + 2 * (size_t)i];
        if (opcode < 0 || opcode > 2 || key < DIET_MIN_KEY || key > DIET_MAX_KEY)
            return 0;
    }
    *q_out = q;
    return 1;
}

int64_t discrete_interval_encoding_tree(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    int q = 0;
    if (!diet_valid(input, length, &q)) return -1;
    size_t required = 8 * (size_t)q;
    if ((required > 0 && output == NULL) || capacity < required) return -2;

    DietNode nodes[DIET_ARENA] = {{0, 0, -1, -1}};
    int used = 0;
    int root = -1;
    int cardinality = 0;
    int interval_count = 0;
    int64_t staged[DIET_MAX_Q] = {0};
    for (int i = 0; i < q; ++i) {
        int64_t opcode = input[1 + 2 * (size_t)i];
        int64_t key = input[2 + 2 * (size_t)i];
        int changed = 0;
        if (opcode == 0) {
            root = diet_insert(nodes, &used, root, key, &interval_count, &changed);
            if (changed) ++cardinality;
        } else if (opcode == 1) {
            root = diet_delete(nodes, &used, root, key, &interval_count, &changed);
            if (changed) --cardinality;
        }
        int present = diet_contains(nodes, root, key);
        staged[i] = (int64_t)(64 * cardinality + 2 * interval_count + present);
    }
    for (int i = 0; i < q; ++i) {
        uint64_t value = (uint64_t)staged[i];
        for (int byte = 0; byte < 8; ++byte)
            output[8 * (size_t)i + (size_t)byte] = (uint8_t)(value >> (8 * byte));
    }
    return (int64_t)required;
}
