/* Online rectangle counts using Fenwick trees over x-blocks and y-values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(24)
#define MAX_Q INT64_C(32)
#define MAX_PARSEABLE_LENGTH ((size_t)187)
#define TREE_STRIDE ((size_t)25)
#define TREE_CELLS ((size_t)150)

static void inner_add(int64_t *trees, size_t n, size_t node,
                      int64_t y, int64_t delta) {
    size_t index = (size_t)y + 1;
    while (index <= n) {
        trees[node * TREE_STRIDE + index] += delta;
        index += index & (~index + 1);
    }
}

static int64_t inner_prefix(const int64_t *trees, size_t node,
                            int64_t y_limit) {
    int64_t total = 0;
    size_t index = (size_t)y_limit;
    while (index > 0) {
        total += trees[node * TREE_STRIDE + index];
        index -= index & (~index + 1);
    }
    return total;
}

static int64_t prefix_count(const int64_t *ys, const int64_t *trees,
                            size_t block_size, size_t x_limit,
                            int64_t y_limit) {
    const size_t full_blocks = x_limit / block_size;
    size_t node = full_blocks;
    int64_t total = 0;
    while (node > 0) {
        total += inner_prefix(trees, node, y_limit);
        node -= node & (~node + 1);
    }
    for (size_t x = full_blocks * block_size; x < x_limit; ++x)
        if (ys[x] < y_limit) ++total;
    return total;
}

int64_t fenwick_tree_in_block_array_rectangle_count(
    const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    const size_t operations_at = 2 + n;
    if (length != operations_at + 5 * q) return -1;

    int64_t ys[24];
    for (size_t x = 0; x < n; ++x) {
        ys[x] = input[2 + x];
        if (ys[x] < 0 || ys[x] >= n_value) return -1;
    }
    for (size_t j = 0; j < q; ++j) {
        const size_t at = operations_at + 5 * j;
        const int64_t kind = input[at];
        if (kind == 0) {
            if (input[at + 1] < 0 || input[at + 1] >= n_value
                    || input[at + 2] < 0 || input[at + 2] >= n_value
                    || input[at + 3] != 0 || input[at + 4] != 0) return -1;
        } else if (kind == 1) {
            if (input[at + 1] < 0 || input[at + 1] > input[at + 2]
                    || input[at + 2] > n_value
                    || input[at + 3] < 0 || input[at + 3] > input[at + 4]
                    || input[at + 4] > n_value) return -1;
        } else {
            return -1;
        }
    }

    size_t block_size = 1;
    while (block_size * block_size < n) ++block_size;
    const size_t block_count = (n + block_size - 1) / block_size;
    int64_t trees[TREE_CELLS] = {0};
    for (size_t x = 0; x < n; ++x) {
        size_t node = x / block_size + 1;
        while (node <= block_count) {
            inner_add(trees, n, node, ys[x], 1);
            node += node & (~node + 1);
        }
    }

    int64_t checksum = 0;
    int64_t query_ordinal = 0;
    for (size_t j = 0; j < q; ++j) {
        const size_t at = operations_at + 5 * j;
        if (input[at] == 0) {
            const size_t x = (size_t)input[at + 1];
            const int64_t new_y = input[at + 2];
            size_t node = x / block_size + 1;
            while (node <= block_count) {
                inner_add(trees, n, node, ys[x], -1);
                inner_add(trees, n, node, new_y, 1);
                node += node & (~node + 1);
            }
            ys[x] = new_y;
        } else {
            const size_t x_left = (size_t)input[at + 1];
            const size_t x_right = (size_t)input[at + 2];
            const int64_t y_low = input[at + 3];
            const int64_t y_high = input[at + 4];
            const int64_t count = prefix_count(ys, trees, block_size, x_right, y_high)
                - prefix_count(ys, trees, block_size, x_left, y_high)
                - prefix_count(ys, trees, block_size, x_right, y_low)
                + prefix_count(ys, trees, block_size, x_left, y_low);
            ++query_ordinal;
            checksum += query_ordinal * count;
        }
    }
    return checksum;
}
