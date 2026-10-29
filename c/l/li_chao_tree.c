#include <stddef.h>
#include <stdint.h>

enum {
    MAX_OPERATIONS = 512,
    MAX_NODES = MAX_OPERATIONS * 24 + 1,
    DOMAIN_LOW = -1000000,
    DOMAIN_HIGH = 1000000,
    COEFFICIENT_LIMIT = 1000
};

#define CHECKSUM_OFFSET INT64_C(1000001001)

typedef struct {
    int64_t slope;
    int64_t intercept;
    int left;
    int right;
    int occupied;
} LineNode;

static int64_t evaluate(int64_t slope, int64_t intercept, int64_t x)
{
    return slope * x + intercept;
}

static int allocate_node(LineNode *nodes, size_t *used)
{
    if (*used >= MAX_NODES) return -1;
    int id = (int)(*used)++;
    nodes[id].slope = 0;
    nodes[id].intercept = 0;
    nodes[id].left = -1;
    nodes[id].right = -1;
    nodes[id].occupied = 0;
    return id;
}

static int insert_at(LineNode *nodes, size_t *used, int node_id,
                     int64_t low, int64_t high, int64_t slope, int64_t intercept)
{
    LineNode *node = &nodes[node_id];
    if (!node->occupied) {
        node->slope = slope;
        node->intercept = intercept;
        node->occupied = 1;
        return 1;
    }

    int64_t middle = low + (high - low) / 2;
    if (evaluate(slope, intercept, middle) < evaluate(node->slope, node->intercept, middle)) {
        int64_t saved_slope = node->slope;
        int64_t saved_intercept = node->intercept;
        node->slope = slope;
        node->intercept = intercept;
        slope = saved_slope;
        intercept = saved_intercept;
    }
    if (low == high) return 1;

    int child;
    int64_t next_low;
    int64_t next_high;
    if (evaluate(slope, intercept, low) < evaluate(node->slope, node->intercept, low)) {
        child = node->left;
        next_low = low;
        next_high = middle;
        if (child < 0) {
            child = allocate_node(nodes, used);
            if (child < 0) return 0;
            nodes[node_id].left = child;
        }
    } else if (evaluate(slope, intercept, high) < evaluate(node->slope, node->intercept, high)) {
        child = node->right;
        next_low = middle + 1;
        next_high = high;
        if (child < 0) {
            child = allocate_node(nodes, used);
            if (child < 0) return 0;
            nodes[node_id].right = child;
        }
    } else {
        return 1;
    }
    return insert_at(nodes, used, child, next_low, next_high, slope, intercept);
}

static int64_t query_min(const LineNode *nodes, int node_id, int64_t low,
                         int64_t high, int64_t x)
{
    const LineNode *node = &nodes[node_id];
    int64_t best = evaluate(node->slope, node->intercept, x);
    if (low == high) return best;
    int64_t middle = low + (high - low) / 2;
    int child = x <= middle ? node->left : node->right;
    if (child >= 0) {
        int64_t nested = query_min(nodes, child,
                                   x <= middle ? low : middle + 1,
                                   x <= middle ? middle : high, x);
        if (nested < best) best = nested;
    }
    return best;
}

int64_t li_chao_tree(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > 1 + 3 * MAX_OPERATIONS) return -1;
    int64_t operation_count_value = values[0];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    size_t operation_count = (size_t)operation_count_value;
    if (length != 1 + 3 * operation_count) return -1;

    LineNode nodes[MAX_NODES];
    size_t used = 0;
    int root = -1;
    size_t inserted = 0;
    size_t query_number = 0;
    int64_t checksum = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        size_t offset = 1 + 3 * operation;
        int64_t opcode = values[offset];
        int64_t first = values[offset + 1];
        int64_t second = values[offset + 2];
        if (opcode == 0) {
            if (first < -COEFFICIENT_LIMIT || first > COEFFICIENT_LIMIT
                || second < -COEFFICIENT_LIMIT || second > COEFFICIENT_LIMIT) return -1;
            if (root < 0) {
                root = allocate_node(nodes, &used);
                if (root < 0) return -1;
            }
            if (!insert_at(nodes, &used, root, DOMAIN_LOW, DOMAIN_HIGH, first, second)) return -1;
            ++inserted;
        } else if (opcode == 1) {
            if (first < DOMAIN_LOW || first > DOMAIN_HIGH || second != 0 || inserted == 0) return -1;
            int64_t answer = query_min(nodes, root, DOMAIN_LOW, DOMAIN_HIGH, first);
            ++query_number;
            checksum += (int64_t)query_number * (answer + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return checksum;
}
