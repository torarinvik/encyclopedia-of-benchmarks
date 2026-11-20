/* Mutable value trees stored at Fenwick position nodes for range selection. */
#include <stddef.h>
#include <stdint.h>

#define FWK_N 12
#define FWK_Q 16
#define FWK_VALUES 61
#define FWK_NODES 1280

typedef struct {
    int left[FWK_NODES + 1];
    int right[FWK_NODES + 1];
    int count[FWK_NODES + 1];
    int used;
} fwk_pool;

static int fwk_change(fwk_pool *pool, int root, int low, int high,
                      int coordinate, int delta)
{
    if (root == 0) root = ++pool->used;
    pool->count[root] += delta;
    if (high - low > 1) {
        const int middle = (low + high) / 2;
        if (coordinate < middle)
            pool->left[root] = fwk_change(pool, pool->left[root], low, middle, coordinate, delta);
        else
            pool->right[root] = fwk_change(pool, pool->right[root], middle, high, coordinate, delta);
    }
    return root;
}

static void fwk_apply(fwk_pool *pool, int roots[FWK_N + 1], int n,
                      int position, int value, int delta)
{
    int node = position + 1;
    while (node <= n) {
        roots[node] = fwk_change(pool, roots[node], 0, FWK_VALUES, value + 30, delta);
        node += node & -node;
    }
}

int64_t fenwick_weighted_segment_tree_range_kth(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 79) return INT64_MIN;
    if (input[0] < 1 || input[0] > FWK_N || input[1] < 0 || input[1] > FWK_Q) return INT64_MIN;
    const int n = (int)input[0];
    const int q = (int)input[1];
    if (length != (size_t)(2 + n + 4 * q)) return INT64_MIN;

    int current[FWK_N] = {0};
    int roots[FWK_N + 1] = {0};
    fwk_pool pool = {0};
    for (int i = 0; i < n; ++i) {
        if (input[2 + i] < -30 || input[2 + i] > 30) return INT64_MIN;
        current[i] = (int)input[2 + i];
        fwk_apply(&pool, roots, n, i, current[i], 1);
    }

    int64_t checksum = 0;
    int query_number = 0;
    size_t cursor = (size_t)(2 + n);
    for (int op = 0; op < q; ++op) {
        const int64_t opcode = input[cursor];
        const int64_t first = input[cursor + 1];
        const int64_t second = input[cursor + 2];
        const int64_t third = input[cursor + 3];
        cursor += 4;
        if (opcode == 0) {
            if (first < 0 || first >= n || second < -30 || second > 30 || third != 0) return INT64_MIN;
            const int position = (int)first;
            fwk_apply(&pool, roots, n, position, current[position], -1);
            current[position] = (int)second;
            fwk_apply(&pool, roots, n, position, current[position], 1);
        } else if (opcode == 1) {
            if (first < 0 || first >= second || second > n || third < 1 || third > second - first)
                return INT64_MIN;
            int left_roots[FWK_N + 1];
            int right_roots[FWK_N + 1];
            int left_size = 0, right_size = 0;
            for (int node = (int)first; node > 0; node -= node & -node)
                left_roots[left_size++] = roots[node];
            for (int node = (int)second; node > 0; node -= node & -node)
                right_roots[right_size++] = roots[node];
            int low = 0, high = FWK_VALUES;
            int64_t rank = third;
            while (high - low > 1) {
                const int middle = (low + high) / 2;
                int64_t left_count = 0;
                for (int i = 0; i < right_size; ++i) left_count += pool.count[pool.left[right_roots[i]]];
                for (int i = 0; i < left_size; ++i) left_count -= pool.count[pool.left[left_roots[i]]];
                if (rank <= left_count) {
                    for (int i = 0; i < right_size; ++i) right_roots[i] = pool.left[right_roots[i]];
                    for (int i = 0; i < left_size; ++i) left_roots[i] = pool.left[left_roots[i]];
                    high = middle;
                } else {
                    rank -= left_count;
                    for (int i = 0; i < right_size; ++i) right_roots[i] = pool.right[right_roots[i]];
                    for (int i = 0; i < left_size; ++i) left_roots[i] = pool.right[left_roots[i]];
                    low = middle;
                }
            }
            checksum += (int64_t)(query_number + 1) * (low - 30);
            ++query_number;
        } else {
            return INT64_MIN;
        }
    }
    return checksum;
}
