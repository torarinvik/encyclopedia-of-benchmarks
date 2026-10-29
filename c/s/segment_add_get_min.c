#include <stddef.h>
#include <stdint.h>

enum {
    MAX_INITIAL_SEGMENTS = 16,
    MAX_OPERATIONS = 32,
    DOMAIN_LOW = -32,
    DOMAIN_HIGH = 31,
    DOMAIN_RIGHT = 32,
    COEFFICIENT_LIMIT = 1000,
    TREE_CAPACITY = 4 * 64 + 8
};

#define INFINITY_VALUE INT64_C(1000000000000)
#define CHECKSUM_OFFSET INT64_C(33001)
#define MAX_INPUT_LENGTH (2 + 4 * MAX_INITIAL_SEGMENTS + 5 * MAX_OPERATIONS)

typedef struct {
    int64_t slope;
    int64_t intercept;
    int occupied;
} LineNode;

static int64_t evaluate(int64_t slope, int64_t intercept, int64_t x)
{
    return slope * x + intercept;
}

static void add_line(LineNode *tree, size_t node, int64_t low, int64_t high,
                     int64_t slope, int64_t intercept)
{
    if (!tree[node].occupied) {
        tree[node].slope = slope;
        tree[node].intercept = intercept;
        tree[node].occupied = 1;
        return;
    }

    const int64_t middle = low + (high - low) / 2;
    if (evaluate(slope, intercept, middle)
        < evaluate(tree[node].slope, tree[node].intercept, middle)) {
        const int64_t old_slope = tree[node].slope;
        const int64_t old_intercept = tree[node].intercept;
        tree[node].slope = slope;
        tree[node].intercept = intercept;
        slope = old_slope;
        intercept = old_intercept;
    }
    if (low == high) return;

    if (evaluate(slope, intercept, low)
        < evaluate(tree[node].slope, tree[node].intercept, low)) {
        add_line(tree, 2 * node, low, middle, slope, intercept);
    } else if (evaluate(slope, intercept, high)
               < evaluate(tree[node].slope, tree[node].intercept, high)) {
        add_line(tree, 2 * node + 1, middle + 1, high, slope, intercept);
    }
}

static void add_segment(LineNode *tree, size_t node, int64_t low, int64_t high,
                        int64_t query_low, int64_t query_high,
                        int64_t slope, int64_t intercept)
{
    if (query_high <= low || high < query_low) return;
    if (query_low <= low && high < query_high) {
        add_line(tree, node, low, high, slope, intercept);
        return;
    }
    const int64_t middle = low + (high - low) / 2;
    add_segment(tree, 2 * node, low, middle, query_low, query_high, slope, intercept);
    add_segment(tree, 2 * node + 1, middle + 1, high, query_low, query_high, slope, intercept);
}

static int64_t minimum_at(const LineNode *tree, size_t node, int64_t low,
                          int64_t high, int64_t x)
{
    int64_t best = INFINITY_VALUE;
    if (tree[node].occupied)
        best = evaluate(tree[node].slope, tree[node].intercept, x);
    if (low == high) return best;

    const int64_t middle = low + (high - low) / 2;
    const size_t child = x <= middle ? 2 * node : 2 * node + 1;
    const int64_t nested = minimum_at(tree, child,
                                      x <= middle ? low : middle + 1,
                                      x <= middle ? middle : high, x);
    return nested < best ? nested : best;
}

static int valid_segment(int64_t left, int64_t right,
                         int64_t slope, int64_t intercept)
{
    return left >= DOMAIN_LOW && left < right && right <= DOMAIN_RIGHT
        && slope >= -COEFFICIENT_LIMIT && slope <= COEFFICIENT_LIMIT
        && intercept >= -COEFFICIENT_LIMIT && intercept <= COEFFICIENT_LIMIT;
}

int64_t segment_add_get_min(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t initial_value = values[0];
    const int64_t operation_value = values[1];
    if (initial_value < 0 || initial_value > MAX_INITIAL_SEGMENTS
        || operation_value < 0 || operation_value > MAX_OPERATIONS) return -1;
    const size_t initial_count = (size_t)initial_value;
    const size_t operation_count = (size_t)operation_value;

    LineNode tree[TREE_CAPACITY] = {{0}};
    size_t position = 2;
    for (size_t index = 0; index < initial_count; ++index) {
        if (length - position < 4) return -1;
        const int64_t left = values[position];
        const int64_t right = values[position + 1];
        const int64_t slope = values[position + 2];
        const int64_t intercept = values[position + 3];
        if (!valid_segment(left, right, slope, intercept)) return -1;
        add_segment(tree, 1, DOMAIN_LOW, DOMAIN_HIGH, left, right, slope, intercept);
        position += 4;
    }

    int64_t checksum = 0;
    int64_t query_number = 0;
    for (size_t index = 0; index < operation_count; ++index) {
        if (position >= length) return -1;
        const int64_t opcode = values[position++];
        if (opcode == 0) {
            if (length - position < 4) return -1;
            const int64_t left = values[position];
            const int64_t right = values[position + 1];
            const int64_t slope = values[position + 2];
            const int64_t intercept = values[position + 3];
            if (!valid_segment(left, right, slope, intercept)) return -1;
            add_segment(tree, 1, DOMAIN_LOW, DOMAIN_HIGH, left, right, slope, intercept);
            position += 4;
        } else if (opcode == 1) {
            if (position >= length) return -1;
            const int64_t x = values[position++];
            if (x < DOMAIN_LOW || x > DOMAIN_HIGH) return -1;
            const int64_t answer = minimum_at(tree, 1, DOMAIN_LOW, DOMAIN_HIGH, x);
            ++query_number;
            checksum += query_number * (answer + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
