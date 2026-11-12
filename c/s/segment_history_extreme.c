/* Historical maximum segment tree with ordered lazy add/assign summaries. */
#include <stddef.h>
#include <stdint.h>

#define SH_MAX_N 32
#define SH_MAX_Q 32
#define SH_MAX_INPUT (2 + SH_MAX_N + 4 * SH_MAX_Q)
#define SH_TREE_SIZE (4 * SH_MAX_N)
#define SH_LIMIT INT64_C(1000)

typedef struct {
    int64_t maximum;
    int64_t history_maximum;
    int64_t add;
    int64_t add_peak;
    int64_t set_value;
    int64_t set_peak;
    int has_set;
} ShNode;

static int64_t sh_max(int64_t a, int64_t b) { return a > b ? a : b; }

static void sh_apply_add_summary(ShNode *node, int64_t net, int64_t peak) {
    node->history_maximum = sh_max(node->history_maximum, node->maximum + peak);
    node->maximum += net;
    if (node->has_set) {
        node->set_peak = sh_max(node->set_peak, node->set_value + peak);
        node->set_value += net;
    } else {
        node->add_peak = sh_max(node->add_peak, node->add + peak);
        node->add += net;
    }
}

static void sh_apply_add(ShNode *node, int64_t delta) {
    if (node->has_set) {
        node->set_peak = sh_max(node->set_peak, node->set_value + delta);
        node->set_value += delta;
    } else {
        node->add_peak = sh_max(node->add_peak, node->add + delta);
        node->add += delta;
    }
    node->history_maximum = sh_max(node->history_maximum, node->maximum + delta);
    node->maximum += delta;
}

static void sh_apply_set_summary(ShNode *node, int64_t value, int64_t peak) {
    node->history_maximum = sh_max(node->history_maximum, peak);
    node->maximum = value;
    if (node->has_set) {
        node->set_peak = sh_max(node->set_peak, peak);
        node->set_value = value;
    } else {
        node->has_set = 1;
        node->set_peak = peak;
        node->set_value = value;
    }
}

static void sh_apply_set(ShNode *node, int64_t value) {
    node->history_maximum = sh_max(node->history_maximum, value);
    node->maximum = value;
    if (node->has_set) node->set_peak = sh_max(node->set_peak, value);
    else {
        node->has_set = 1;
        node->set_peak = value;
    }
    node->set_value = value;
}

static void sh_push(ShNode tree[SH_TREE_SIZE], size_t node) {
    ShNode *parent = &tree[node];
    if (parent->add != 0 || parent->add_peak != 0) {
        sh_apply_add_summary(&tree[node * 2], parent->add, parent->add_peak);
        sh_apply_add_summary(&tree[node * 2 + 1], parent->add, parent->add_peak);
        parent->add = 0;
        parent->add_peak = 0;
    }
    if (parent->has_set) {
        sh_apply_set_summary(&tree[node * 2], parent->set_value, parent->set_peak);
        sh_apply_set_summary(&tree[node * 2 + 1], parent->set_value, parent->set_peak);
        parent->has_set = 0;
        parent->set_value = 0;
        parent->set_peak = 0;
    }
}

static void sh_pull(ShNode tree[SH_TREE_SIZE], size_t node) {
    tree[node].maximum = sh_max(tree[node * 2].maximum, tree[node * 2 + 1].maximum);
    tree[node].history_maximum = sh_max(tree[node * 2].history_maximum,
                                        tree[node * 2 + 1].history_maximum);
}

static void sh_build(ShNode tree[SH_TREE_SIZE], const int64_t *input,
                     size_t offset, size_t node, size_t left, size_t right) {
    if (right - left == 1) {
        tree[node].maximum = input[offset + left];
        tree[node].history_maximum = input[offset + left];
        return;
    }
    size_t middle = left + (right - left) / 2;
    sh_build(tree, input, offset, node * 2, left, middle);
    sh_build(tree, input, offset, node * 2 + 1, middle, right);
    sh_pull(tree, node);
}

static void sh_update(ShNode tree[SH_TREE_SIZE], size_t node, size_t left, size_t right,
                      size_t query_left, size_t query_right, int is_assignment, int64_t value) {
    if (query_left <= left && right <= query_right) {
        if (is_assignment) sh_apply_set(&tree[node], value);
        else sh_apply_add(&tree[node], value);
        return;
    }
    sh_push(tree, node);
    size_t middle = left + (right - left) / 2;
    if (query_left < middle) sh_update(tree, node * 2, left, middle, query_left, query_right, is_assignment, value);
    if (middle < query_right) sh_update(tree, node * 2 + 1, middle, right, query_left, query_right, is_assignment, value);
    sh_pull(tree, node);
}

static int64_t sh_query(ShNode tree[SH_TREE_SIZE], size_t node, size_t left, size_t right,
                        size_t query_left, size_t query_right, int historical) {
    if (query_left <= left && right <= query_right)
        return historical ? tree[node].history_maximum : tree[node].maximum;
    sh_push(tree, node);
    size_t middle = left + (right - left) / 2;
    int64_t answer = INT64_MIN;
    if (query_left < middle)
        answer = sh_query(tree, node * 2, left, middle, query_left, query_right, historical);
    if (middle < query_right) {
        int64_t other = sh_query(tree, node * 2 + 1, middle, right, query_left, query_right, historical);
        answer = sh_max(answer, other);
    }
    return answer;
}

static void sh_write_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t segment_history_extreme(const int64_t *input, size_t input_length,
                                uint8_t *output, size_t output_capacity) {
    if (input == NULL || input_length < 2 || input_length > SH_MAX_INPUT) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > SH_MAX_N || q_value < 0 || q_value > SH_MAX_Q) return -1;
    size_t n = (size_t)n_value, q = (size_t)q_value;
    if (input_length != 2 + n + 4 * q) return -1;
    size_t operation_offset = 2 + n;
    for (size_t i = 0; i < n; ++i)
        if (input[2 + i] < -SH_LIMIT || input[2 + i] > SH_LIMIT) return -1;
    for (size_t i = 0; i < q; ++i) {
        const int64_t *record = input + operation_offset + 4 * i;
        int64_t op = record[0], left = record[1], right = record[2], arg = record[3];
        if (op < 0 || op > 3 || left < 0 || right <= left || right > n_value) return -1;
        if (op < 2) {
            if (arg < -SH_LIMIT || arg > SH_LIMIT) return -1;
        } else if (arg != 0) return -1;
    }

    ShNode tree[SH_TREE_SIZE] = {0};
    int64_t staged[SH_MAX_Q];
    size_t answer_count = 0;
    sh_build(tree, input, 2, 1, 0, n);
    for (size_t i = 0; i < q; ++i) {
        const int64_t *record = input + operation_offset + 4 * i;
        int op = (int)record[0];
        size_t left = (size_t)record[1], right = (size_t)record[2];
        int64_t arg = record[3];
        if (op == 0 || op == 1)
            sh_update(tree, 1, 0, n, left, right, op == 0, arg);
        else
            staged[answer_count++] = sh_query(tree, 1, 0, n, left, right, op == 3);
    }
    size_t output_bytes = 8 * answer_count;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t i = 0; i < answer_count; ++i) sh_write_i64(output, 8 * i, staged[i]);
    return (int64_t)output_bytes;
}
