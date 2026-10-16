#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 256
#define MAX_OPERATIONS 512
#define MAX_INPUT_LENGTH (2 + MAX_ITEMS + 4 * MAX_OPERATIONS)
#define VALUE_LIMIT INT64_C(1000000)
#define QUERY_OFFSET INT64_C(131328000001)

static void apply(int64_t *tree, int64_t *lazy, size_t node, size_t segment_length, int64_t delta)
{
    tree[node] += delta * (int64_t)segment_length;
    lazy[node] += delta;
}

static void push(int64_t *tree, int64_t *lazy, size_t node, size_t segment_length)
{
    if (segment_length > 1 && lazy[node] != 0) {
        size_t child_length = segment_length / 2;
        apply(tree, lazy, 2 * node, child_length, lazy[node]);
        apply(tree, lazy, 2 * node + 1, child_length, lazy[node]);
        lazy[node] = 0;
    }
}

static void range_add(int64_t *tree, int64_t *lazy, size_t node,
                      size_t low, size_t high, size_t query_low, size_t query_high,
                      int64_t delta)
{
    if (query_low <= low && high <= query_high) {
        apply(tree, lazy, node, high - low, delta);
        return;
    }
    push(tree, lazy, node, high - low);
    size_t middle = (low + high) / 2;
    if (query_low < middle)
        range_add(tree, lazy, 2 * node, low, middle, query_low, query_high, delta);
    if (query_high > middle)
        range_add(tree, lazy, 2 * node + 1, middle, high, query_low, query_high, delta);
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

static int64_t range_sum(int64_t *tree, int64_t *lazy, size_t node,
                         size_t low, size_t high, size_t query_low, size_t query_high)
{
    if (query_low <= low && high <= query_high) return tree[node];
    push(tree, lazy, node, high - low);
    size_t middle = (low + high) / 2;
    int64_t result = 0;
    if (query_low < middle)
        result += range_sum(tree, lazy, 2 * node, low, middle, query_low, query_high);
    if (query_high > middle)
        result += range_sum(tree, lazy, 2 * node + 1, middle, high, query_low, query_high);
    return result;
}

int64_t lazy_segment_tree_range_add_sum(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    int64_t item_count_value = values[0];
    if (item_count_value < 1 || item_count_value > MAX_ITEMS) return -1;
    size_t item_count = (size_t)item_count_value;
    if (length < item_count + 2) return -1;
    int64_t operation_count_value = values[item_count + 1];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    size_t operation_count = (size_t)operation_count_value;
    if (length != item_count + 2 + 4 * operation_count) return -1;

    for (size_t i = 0; i < item_count; ++i)
        if (values[i + 1] < -VALUE_LIMIT || values[i + 1] > VALUE_LIMIT) return -1;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        size_t position = item_count + 2 + 4 * operation;
        int64_t opcode = values[position];
        int64_t left = values[position + 1];
        int64_t right = values[position + 2];
        int64_t delta = values[position + 3];
        if (left < 0 || left >= right || right > item_count_value) return -1;
        if (opcode == 0) {
            if (delta < -VALUE_LIMIT || delta > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (delta != 0) return -1;
        } else return -1;
    }

    size_t base = 1;
    while (base < item_count) base *= 2;
    int64_t tree[2 * MAX_ITEMS] = {0};
    int64_t lazy[2 * MAX_ITEMS] = {0};
    for (size_t i = 0; i < item_count; ++i) tree[base + i] = values[i + 1];
    for (size_t node = base; node-- > 1;)
        tree[node] = tree[2 * node] + tree[2 * node + 1];

    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        size_t position = item_count + 2 + 4 * operation;
        size_t left = (size_t)values[position + 1];
        size_t right = (size_t)values[position + 2];
        if (values[position] == 0) {
            range_add(tree, lazy, 1, 0, base, left, right, values[position + 3]);
        } else {
            checksum += range_sum(tree, lazy, 1, 0, base, left, right) + QUERY_OFFSET;
        }
    }
    return checksum;
}
