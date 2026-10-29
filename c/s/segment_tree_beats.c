#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_OPERATIONS 128
#define MAX_INPUT_VALUES (2 + MAX_ITEMS + 4 * MAX_OPERATIONS)
#define VALUE_LIMIT INT64_C(1000000)
#define INFINITY_VALUE (INT64_MAX / 4)
#define QUERY_OFFSET INT64_C(8256000001)

typedef struct {
    int64_t sum;
    int64_t max1;
    int64_t max2;
    int64_t min1;
    int64_t min2;
    int64_t add;
    size_t max_count;
    size_t min_count;
} SegmentNode;

static void pull(SegmentNode *tree, size_t node)
{
    const SegmentNode *left = &tree[2 * node];
    const SegmentNode *right = &tree[2 * node + 1];
    SegmentNode *current = &tree[node];
    current->sum = left->sum + right->sum;
    current->add = 0;

    if (left->max1 == right->max1) {
        current->max1 = left->max1;
        current->max2 = left->max2 > right->max2 ? left->max2 : right->max2;
        current->max_count = left->max_count + right->max_count;
    } else if (left->max1 > right->max1) {
        current->max1 = left->max1;
        current->max2 = left->max2 > right->max1 ? left->max2 : right->max1;
        current->max_count = left->max_count;
    } else {
        current->max1 = right->max1;
        current->max2 = left->max1 > right->max2 ? left->max1 : right->max2;
        current->max_count = right->max_count;
    }

    if (left->min1 == right->min1) {
        current->min1 = left->min1;
        current->min2 = left->min2 < right->min2 ? left->min2 : right->min2;
        current->min_count = left->min_count + right->min_count;
    } else if (left->min1 < right->min1) {
        current->min1 = left->min1;
        current->min2 = left->min2 < right->min1 ? left->min2 : right->min1;
        current->min_count = left->min_count;
    } else {
        current->min1 = right->min1;
        current->min2 = left->min1 < right->min2 ? left->min1 : right->min2;
        current->min_count = right->min_count;
    }
}

static void build(SegmentNode *tree, const int64_t *values,
                  size_t node, size_t low, size_t high)
{
    if (high - low == 1) {
        const int64_t value = values[low];
        tree[node] = (SegmentNode){
            .sum = value, .max1 = value, .max2 = -INFINITY_VALUE,
            .min1 = value, .min2 = INFINITY_VALUE,
            .add = 0, .max_count = 1, .min_count = 1
        };
        return;
    }
    const size_t middle = low + (high - low) / 2;
    build(tree, values, 2 * node, low, middle);
    build(tree, values, 2 * node + 1, middle, high);
    pull(tree, node);
}

static void apply_add(SegmentNode *item, size_t length, int64_t delta)
{
    item->sum += delta * (int64_t)length;
    item->max1 += delta;
    item->min1 += delta;
    if (item->max2 != -INFINITY_VALUE) item->max2 += delta;
    if (item->min2 != INFINITY_VALUE) item->min2 += delta;
    item->add += delta;
}

static void apply_chmin(SegmentNode *item, int64_t ceiling)
{
    if (item->max1 <= ceiling) return;
    item->sum += (ceiling - item->max1) * (int64_t)item->max_count;
    if (item->min1 == item->max1) item->min1 = ceiling;
    else if (item->min2 == item->max1) item->min2 = ceiling;
    item->max1 = ceiling;
}

static void apply_chmax(SegmentNode *item, int64_t floor)
{
    if (item->min1 >= floor) return;
    item->sum += (floor - item->min1) * (int64_t)item->min_count;
    if (item->max1 == item->min1) item->max1 = floor;
    else if (item->max2 == item->min1) item->max2 = floor;
    item->min1 = floor;
}

static void push(SegmentNode *tree, size_t node, size_t low, size_t high)
{
    if (high - low == 1) return;
    const size_t middle = low + (high - low) / 2;
    SegmentNode *parent = &tree[node];
    SegmentNode *left = &tree[2 * node];
    SegmentNode *right = &tree[2 * node + 1];
    if (parent->add != 0) {
        apply_add(left, middle - low, parent->add);
        apply_add(right, high - middle, parent->add);
        parent->add = 0;
    }
    if (left->max1 > parent->max1) apply_chmin(left, parent->max1);
    if (right->max1 > parent->max1) apply_chmin(right, parent->max1);
    if (left->min1 < parent->min1) apply_chmax(left, parent->min1);
    if (right->min1 < parent->min1) apply_chmax(right, parent->min1);
}

static void range_add(SegmentNode *tree, size_t node, size_t low, size_t high,
                      size_t query_low, size_t query_high, int64_t delta)
{
    if (query_high <= low || high <= query_low || delta == 0) return;
    if (query_low <= low && high <= query_high) {
        apply_add(&tree[node], high - low, delta);
        return;
    }
    push(tree, node, low, high);
    const size_t middle = low + (high - low) / 2;
    range_add(tree, 2 * node, low, middle, query_low, query_high, delta);
    range_add(tree, 2 * node + 1, middle, high, query_low, query_high, delta);
    pull(tree, node);
}

static void range_chmin(SegmentNode *tree, size_t node, size_t low, size_t high,
                        size_t query_low, size_t query_high, int64_t ceiling)
{
    SegmentNode *item = &tree[node];
    if (query_high <= low || high <= query_low || item->max1 <= ceiling) return;
    if (query_low <= low && high <= query_high && item->max2 < ceiling) {
        apply_chmin(item, ceiling);
        return;
    }
    push(tree, node, low, high);
    const size_t middle = low + (high - low) / 2;
    range_chmin(tree, 2 * node, low, middle, query_low, query_high, ceiling);
    range_chmin(tree, 2 * node + 1, middle, high, query_low, query_high, ceiling);
    pull(tree, node);
}

static void range_chmax(SegmentNode *tree, size_t node, size_t low, size_t high,
                        size_t query_low, size_t query_high, int64_t floor)
{
    SegmentNode *item = &tree[node];
    if (query_high <= low || high <= query_low || item->min1 >= floor) return;
    if (query_low <= low && high <= query_high && item->min2 > floor) {
        apply_chmax(item, floor);
        return;
    }
    push(tree, node, low, high);
    const size_t middle = low + (high - low) / 2;
    range_chmax(tree, 2 * node, low, middle, query_low, query_high, floor);
    range_chmax(tree, 2 * node + 1, middle, high, query_low, query_high, floor);
    pull(tree, node);
}

static int64_t range_sum(SegmentNode *tree, size_t node, size_t low, size_t high,
                         size_t query_low, size_t query_high)
{
    if (query_high <= low || high <= query_low) return 0;
    if (query_low <= low && high <= query_high) return tree[node].sum;
    push(tree, node, low, high);
    const size_t middle = low + (high - low) / 2;
    return range_sum(tree, 2 * node, low, middle, query_low, query_high) +
           range_sum(tree, 2 * node + 1, middle, high, query_low, query_high);
}

int64_t segment_tree_beats(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t item_count_value = values[0];
    if (item_count_value < 1 || item_count_value > MAX_ITEMS) return -1;
    const size_t item_count = (size_t)item_count_value;
    if (length < item_count + 2) return -1;
    const int64_t operation_count_value = values[item_count + 1];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    if (length != item_count + 2 + 4 * operation_count) return -1;

    for (size_t i = 0; i < item_count; ++i)
        if (values[i + 1] < -VALUE_LIMIT || values[i + 1] > VALUE_LIMIT) return -1;
    for (size_t i = 0; i < operation_count; ++i) {
        const size_t position = item_count + 2 + 4 * i;
        const int64_t opcode = values[position];
        const int64_t left = values[position + 1];
        const int64_t right = values[position + 2];
        const int64_t argument = values[position + 3];
        if (opcode < 0 || opcode > 3 || left < 0 || left >= right || right > item_count_value) return -1;
        if (opcode == 3) {
            if (argument != 0) return -1;
        } else if (argument < -VALUE_LIMIT || argument > VALUE_LIMIT) return -1;
    }

    SegmentNode tree[4 * MAX_ITEMS];
    build(tree, values + 1, 1, 0, item_count);
    int64_t checksum = 0;
    int64_t query_ordinal = 0;
    for (size_t i = 0; i < operation_count; ++i) {
        const size_t position = item_count + 2 + 4 * i;
        const size_t left = (size_t)values[position + 1];
        const size_t right = (size_t)values[position + 2];
        const int64_t argument = values[position + 3];
        switch (values[position]) {
        case 0: range_chmin(tree, 1, 0, item_count, left, right, argument); break;
        case 1: range_chmax(tree, 1, 0, item_count, left, right, argument); break;
        case 2: range_add(tree, 1, 0, item_count, left, right, argument); break;
        default:
            query_ordinal += 1;
            checksum += query_ordinal * (range_sum(tree, 1, 0, item_count, left, right) + QUERY_OFFSET);
            break;
        }
    }
    return checksum;
}
