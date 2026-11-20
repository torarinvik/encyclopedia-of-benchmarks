/* Lazy range addition and sum-monoid max_right boundary searches. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

static void apply(int64_t *tree, int64_t *lazy, size_t node,
                  size_t segment_length, int64_t delta)
{
    tree[node] += delta * (int64_t)segment_length;
    lazy[node] += delta;
}

static void push(int64_t *tree, int64_t *lazy, size_t node,
                 size_t segment_length)
{
    if (segment_length > 1 && lazy[node] != 0) {
        const size_t child_length = segment_length / 2;
        apply(tree, lazy, 2 * node, child_length, lazy[node]);
        apply(tree, lazy, 2 * node + 1, child_length, lazy[node]);
        lazy[node] = 0;
    }
}

static void range_add(int64_t *tree, int64_t *lazy, size_t node,
                      size_t low, size_t high, size_t query_low,
                      size_t query_high, int64_t delta)
{
    if (query_low >= query_high) return;
    if (query_high <= low || high <= query_low) return;
    if (query_low <= low && high <= query_high) {
        apply(tree, lazy, node, high - low, delta);
        return;
    }
    push(tree, lazy, node, high - low);
    const size_t middle = (low + high) / 2;
    if (query_low < middle)
        range_add(tree, lazy, 2 * node, low, middle, query_low, query_high, delta);
    if (query_high > middle)
        range_add(tree, lazy, 2 * node + 1, middle, high, query_low, query_high, delta);
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

/* Return the first failing endpoint, or high when this subtree is accepted. */
static size_t max_right(int64_t *tree, int64_t *lazy, size_t node,
                        size_t low, size_t high, size_t n, size_t left,
                        int64_t limit, int64_t *accumulated)
{
    if (high <= left) return high;
    if (low >= n) return n;
    if (left <= low && high <= n && *accumulated + tree[node] <= limit) {
        *accumulated += tree[node];
        return high;
    }
    if (high - low == 1) return low;

    push(tree, lazy, node, high - low);
    const size_t middle = (low + high) / 2;
    const size_t first = max_right(tree, lazy, 2 * node, low, middle,
                                   n, left, limit, accumulated);
    if (first < middle && first >= left) return first;
    return max_right(tree, lazy, 2 * node + 1, middle, high,
                     n, left, limit, accumulated);
}

int64_t lazy_segment_tree_range_add_max_right(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 67) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 12) return -1;
    const size_t n = (size_t)input[0];
    const size_t operations = (size_t)input[1];
    if (length != 2 + n + 4 * operations) return -1;

    for (size_t i = 0; i < n; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 31) return -1;
    for (size_t operation = 0; operation < operations; ++operation) {
        const size_t position = 2 + n + 4 * operation;
        const int64_t opcode = input[position];
        const int64_t left = input[position + 1];
        const int64_t right = input[position + 2];
        const int64_t extra = input[position + 3];
        if (opcode == 0) {
            if (left < 0 || left > (int64_t)n || right < left || right > (int64_t)n
                    || extra < 0 || extra > 31) return -1;
        } else if (opcode == 1) {
            if (left < 0 || left > (int64_t)n || right < 0 || right > 8192
                    || extra != 0) return -1;
        } else return -1;
    }

    size_t size = 1;
    while (size < n) size *= 2;
    int64_t tree[64] = {0};
    int64_t lazy[64] = {0};
    for (size_t i = 0; i < n; ++i) tree[size + i] = input[2 + i];
    for (size_t node = size; node > 1; ) {
        --node;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    size_t query_index = 0;
    int64_t result = 0;
    for (size_t operation = 0; operation < operations; ++operation) {
        const size_t position = 2 + n + 4 * operation;
        const size_t left = (size_t)input[position + 1];
        const size_t right = (size_t)input[position + 2];
        if (input[position] == 0) {
            range_add(tree, lazy, 1, 0, size, left, right, input[position + 3]);
        } else {
            int64_t accumulated = 0;
            const size_t boundary = max_right(tree, lazy, 1, 0, size, n,
                                              left, (int64_t)right, &accumulated);
            result |= (int64_t)boundary << (5 * query_index);
            ++query_index;
        }
    }
    return result;
}
